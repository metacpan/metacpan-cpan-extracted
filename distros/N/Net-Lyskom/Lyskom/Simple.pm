package Net::Lyskom::Simple;
use base qw{Net::Lyskom::Object};

use Net::Lyskom;
use Carp;

=head1 NAME

Net::Lyskom::Simple - module with an easy-to-use subset of Lyskom functions

=head1 SYNOPSIS

  $kom = Net::Lyskom::Simple->new($username, $password, $server)
  $kom->post("Inlägg }t mig", "This is the subject", "This is the body");

=head1 DESCRIPTION



=cut

sub new {
    my $class = shift;
    my ($uname, $pass, $serv) = @_;
    my $s = {};

    $serv = "kom.lysator.liu.se" unless $serv;
    croak "No username given.\n" unless $uname;
    croak "No password given.\n" unless $pass;

    $class = ref($class) if ref($class);
    bless $s, $class;

    $s->{conn} = Net::Lyskom->new(Host => $serv)
      or croak "Failed to connect to server.\n";
    $s->{conn}->login(pers_no => $s->n2n($uname), password => $pass, invisible => 1)
      or croak "Login failed: $s->{conn}->{err_string}\n";

    return $s;
}


sub n2n {
    my $s = shift;
    my $name = shift;

    my @tmp = $s->{conn}->lookup_z_name(name => $name,
					want_pers => 1,
					want_conf => 1
				       );

    return $tmp[0]->conf_no if @tmp==1;
    foreach (@tmp) {
	return $_->conf_no if $name eq $_->name;
    }
    croak "Ambiguous name, aborting.\n" if @tmp > 1;
    croak "Name does not exist, aborting.\n" if @tmp == 0;
}

sub aux {
    my $s = shift;

    return Net::Lyskom::AuxItem->new(tag => $_[0], data => $_[1]);
}

sub post {
    my $s = shift;
    my $conf = shift;
    my $subj = shift;
    my $body = shift;
    my @aux;
    my $ret;

    while (@_) {
	my $tag = shift;
	my $data = shift;
	push @aux, $s->aux($tag,$data)
    }

    $ret = $s->{conn}->create_text(
				   recpt => [$s->n2n($conf)],
				   subject => $subj,
				   body => $body,
				   aux => [@aux]
				  )
      or croak "Text creation failed: $s->{conn}->{err_string}.\n";;

    return $ret;
}

1;
