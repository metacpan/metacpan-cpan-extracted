package QWizard::Storage::SQL;

use strict;
use QWizard::Storage::Base;

our @ISA = qw(QWizard::Storage::Base);

our $VERSION = '3.15';

our %default_opts =
  (
   table => 'QWStorage',
   namecol => 'name',
   valcol => 'value',
  );

sub new {
    my $class = shift;
    my $self;
    %$self = @_;
    map { $self->{$_} = $default_opts{$_} if (!exists($self->{$_})) } (keys(%default_opts));
    return undef if (!$self->{'dbh'});
    my $dbh = $self->{'dbh'};
    $self->{'geth'} = $dbh->prepare("select $self->{valcol} from $self->{table} where $self->{namecol} = ?");
    $self->{'allh'} = $dbh->prepare("select $self->{namecol}, $self->{valcol} from $self->{table}");
    $self->{'cnth'} = $dbh->prepare("select count($self->{valcol}) from $self->{table} where $self->{namecol} = ?");
    $self->{'insh'} = $dbh->prepare("insert into $self->{table} ($self->{namecol}, $self->{valcol}) values(?, ?)");
    $self->{'updh'} = $dbh->prepare("update $self->{table} set $self->{valcol} = ? where $self->{namecol} = ?");
    $self->{'delh'} = $dbh->prepare("delete from $self->{table}");
    bless $self, $class;
}

sub create_table {
    my $self = shift;

    my $xret;					# Return code from execute().

						# Table existence check command.
    my $chk = $self->{'dbh'}->prepare("select * from $self->{table}");

						# Table creation command.
    my $ct = $self->{'dbh'}->prepare("create table $self->{table} (id int, $self->{namecol} varchar(255), $self->{valcol} varchar(65536))");

    #
    # Return without doing anything if the specified table exists.
    #
    $xret = $chk->execute();
    return if($xret == 1);

    #
    # Create the table.
    #
    $ct->execute();
}

sub get_all {
    my $self = shift;
    my $ret;

    $self->{'allh'}->execute();
    while (my $vals = $self->{'allh'}->fetchrow_arrayref()) {
	$ret->{$vals->[0]} = $vals->[1];
    }
    $self->{'allh'}->finish;

    return $ret;
}

sub set {
    my ($self, $it, $value) = @_;

    # check to see if it exists
    $self->{'cnth'}->execute($it);
    my $vals = $self->{'cnth'}->fetchrow_arrayref();
    $self->{'cnth'}->finish;
    if ($vals->[0] == 0) {
	$self->{'insh'}->execute($it, $value);
    } else {
	$self->{'updh'}->execute($value, $it);
    }

    return $value;
}

sub get {
    my ($self, $it) = @_;
    $self->{'geth'}->execute($it);
    my $vals = $self->{'geth'}->fetchrow_arrayref();
    $self->{'geth'}->finish;
    return $vals->[0];
}

sub reset {
    my $self = shift;
    $self->{'delh'}->execute();
}

1;

=pod

=head1 NAME

QWizard::Storage::SQL - Stores data in a SQL database

=head1 SYNOPSIS

  my $st = new QWizard::Storage::SQL(dbh => $DBI_reference);
  $st->create_table();
  $st->set('var', 'value');
  $st->get('var');

=head1 DESCRIPTION

Stores data passed to and from a database table through a passed in
database handle reference.

=head1 AUTHOR

Wes Hardaker, hardaker@users.sourceforge.net

=head1 SEE ALSO

perl(1)

Net-Policy: http://net-policy.sourceforge.net/

=cut
