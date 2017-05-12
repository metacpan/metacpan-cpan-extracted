package SQLite::Work::Mail;
$SQLite::Work::Mail::VERSION = '0.1601';
use strict;
use warnings;

=head1 NAME

SQLite::Work::Mail - send mail with data from an SQLite table.

=head1 VERSION

version 0.1601

=head1 SYNOPSIS

    use SQLite::Work::Mail;

    my $obj = SQLite::Work::Mail->new(%args);

    $obj->send_mail(%args);

=head1 DESCRIPTION

This module is an expansion of SQLite::Work used for
sending email populated by row(s) from a table in
an SQLite database.

=cut

use File::Temp qw(tmpnam);
use SQLite::Work;
use Text::NeatTemplate;

our @ISA = qw(SQLite::Work);

=head1 CLASS METHODS

=head2 new

my $obj = SQLite::Work::Mail->new(
    database=>$database_file,
    report_template=>$report_template,
    default_format=>{
	    'episodes' => {
		'title'=>'title',
		'series_title'=>'title',
	    }
	},
    },
    );

Make a new report object.

Takes the same arguments as L<SQLite::Work>::new().

=cut

sub new {
    my $class = shift;
    my %parameters = (@_);
    my $self = SQLite::Work->new(%parameters);

    $self->{report_template} = '<!--sqlr_contents-->'
	if !defined $parameters{report_template};
    bless ($self, ref ($class) || $class);
} # new

=head1 OBJECT METHODS

=head2 send_email

$obj->send_email();

    $rep->send_email(
	table=>$table,
	where=>\%where,
	not_where=>\%not_where,
	subject=>'My Mail',
	email_col=>$email_col,
	email_address=>\@addresses,
	mailer=>$mailer,
	sort_by=>\@sort_by,
	sort_reversed=>\%sort_reversed,
	show=>\@show,
	limit=>$limit,
	page=>$page,
	row_template=>$row_template,
    );

Select data from a table in the database, and send each
row as a separate email.

Arguments are as follows (in alphabetical order):

=over

=item email_address

An array of email addresses to send the email to.  If this is given,
this will send an email for each matching row, to each address in the array.
Useful for broadcast mailing.

Give either this option or the 'email_col' option.

=item email_col

The name of the column to take email addresses from.  If this is given,
then each row is sent to the email address value in that column for
that row.  Useful for individual notification.

Give either this option or the 'email_address' option.

=item limit

The maximum number of rows to display per page.  If this is zero,
then all rows are displayed in one page.

=item mailer

The name of the mailing program to use.  Allowable values are
'mutt', sendmail, mail, and elm.

=item not_where

A hash containing the column names where the selection criteria
in L<where> should be negated.

=item page

Select which page to generate, if limit is not zero.

=item row_template

The template for each row.  This uses the same format as for L<headers>.
If none is given, then a default row_template will be generated,
depending on which columns are going to be shown (see L<show>).

Therefore it is important that if one provides a row_template, that
it matches the current layout.

The format is as follows:

=over

=item {$colname}

A variable; will display the value of the column, or nothing if
that value is empty.

=item {?colname stuff [$colname] more stuff}

A conditional.  If the value of 'colname' is not empty, this will
display "stuff value-of-column more stuff"; otherwise it displays
nothing.

    {?col1 stuff [$col1] thing [$col2]}

This would use both the values of col1 and col2 if col1 is not
empty.

=item {?colname stuff [$colname] more stuff!!other stuff}

A conditional with "else".  If the value of 'colname' is not empty, this
will display "stuff value-of-column more stuff"; otherwise it displays
"other stuff".

This version can likewise use multiple columns in its display parts.

    {?col1 stuff [$col1] thing [$col2]!![$col3]}

=back

=item show

An array of columns to select; also the order in which they should
be shown when a L<row_template> has not been given.

=item sort_by

An array of column names by which the result should be sorted.

=item sort_reversed

A hash of column names where the sorting given in L<sort_by> should
be reversed.

=item subject

A template for the Subject: line of the emails.

=item table

The table to report on. (required)

=item where

A hash containing selection criteria.  The keys are the column names
and the values are strings suitable for using in a LIKE condition;
that is, '%' is a multi-character wildcard, and '_' is a
single-character wildcard.  All the conditions will be ANDed together.

Yes, this is limited and doesn't use the full power of SQL, but it's
useful enough for most purposes.

=back

=cut
sub send_email ($) {
    my $self = shift;
    my %args = (
	table=>undef,
	limit=>0,
	page=>1,
	sort_by=>[],
	sort_reversed=>{},
	not_where=>{},
	where=>{},
	show=>[],
	row_template=>'',
	subject=>'Notification',
	email_col=>'',
	email_address=>[],
	mailer=>'mail',
	@_
    );

    my $total = $self->get_total_matching(%args);
    my $limit = $args{limit};
    # make the selection, only for one table
    my ($sth1, $sth2) = $self->make_selections(%args,
	table2=>'');

    my @columns = (@{$args{show}}
	? @{$args{show}} 
	: $self->get_colnames($args{table}));
    my %show_cols = ();
    for (my $i = 0; $i < @columns; $i++)
    {
	$show_cols{$columns[$i]} = 1;
    }
    my %nice_cols = $self->set_nice_cols(columns=>\@columns,
	truncate_colnames=>$args{truncate_colnames});

    my $row_template = $self->get_row_template(
	table=>$args{table},
	row_template=>$args{row_template},
	layout=>'fieldval',
	report_style=>'bare',
	columns=>\@columns,
	show_cols=>\%show_cols,
	nice_cols=>\%nice_cols);
    # loop through the rows, sending email
    my $row_hash;
    while ($row_hash = $sth1->fetchrow_hashref)
    {
	$self->send_one_email(row_hash=>$row_hash,
	    row_template=>$row_template,
	    subject=>$args{subject},
	    show_cols=>\%show_cols,
	    email_col=>$args{email_col},
	    email_address=>$args{email_address},
	    mailer=>$args{mailer});
    }

} # send_email

=head1 Private Methods

=head2 send_one_email

=cut
sub send_one_email ($%) {
    my $self = shift;
    my %args = (
	row_hash=>undef,
	row_template=>undef,
	subject=>'Notification',
	show_cols=>undef,
	email_col=>'',
	email_address=>[],
	mailer=>'',
	@_
    );
    my $row_hash = $args{row_hash};
    my $row_template = $args{row_template};
    my %show_cols = %{$args{show_cols}};

    # put output to a temporary output file
    my $outfile = tmpnam();
    open(OUTFILE, ">$outfile") || die "Can't open '$outfile' for writing.";

    my $rowstr = $row_template;
    $rowstr =~ s/{([^}]+)}/$self->{_tobj}->do_replace(data_hash=>$row_hash,show_names=>\%show_cols,targ=>$1)/eg;
    print OUTFILE $rowstr;

    close(OUTFILE);
    if ($args{'debug'})
    {
	print STDERR "outfile=$outfile\n";
    }

    my $subject = $args{subject};
    $subject =~ s/{([^}]+)}/$self->{_tobj}->do_replace(data_hash=>$row_hash,show_names=>\%show_cols,targ=>$1)/eg;
    
    if ($args{'debug'})
    {
	print STDERR "subject=$subject\n";
    }
    if ($args{email_col})
    {
	$self->send_the_actual_mail(email=>$row_hash->{$args{email_col}},
	    mailer=>$args{mailer},
	    subject=>$subject,
	    mailfile=>$outfile);
    }
    elsif (@{$args{email_address}}) # send to list of emails
    {
	foreach my $email (@{$args{email_address}})
	{
	    $self->send_the_actual_mail(email=>$email,
		mailer=>$args{mailer},
		subject=>$subject,
		mailfile=>$outfile);
	}
    }
    unlink($outfile);
} # send_one_email

=head2 send_the_actual_mail

=cut
sub send_the_actual_mail ($%) {
    my $self = shift;
    my %args = (
	email=>'',
	subject=>'Notification',
	mailfile=>'',
	mailer=>'',
	@_
    );
    my $email = $args{email};
    my $subject = $args{subject};
    my $mailfile = $args{mailfile};
    my $mailer = $args{mailer};

    if ($email)
    {
	my $command = '';
	if ($mailer eq 'mutt')
	{
	    $command = "mutt $email -s \"$subject\" -i $mailfile";
	    system($command);
	}
	elsif ($mailer =~ /sendmail$/)
	{
	    # have to add the To: and the Subject:
	    my $tfile = tmpnam();
	    open(TOUT, ">$tfile") || die "Can't open '$tfile' for writing.";

	    print TOUT "To: $email\n";
	    print TOUT "Subject: $subject\n";
	    close(TOUT);

	    $command = $mailer;
	    $command .= " -bm -i <$tfile <$mailfile";
	    system($command);
	    unlink($tfile);
	}
	elsif ($mailer =~ /^mail(x)?$/)
	{
	    $command = $mailer;
	    $command .= " $email -s \"$subject\" < $mailfile";
	    system($command);
	}
	elsif ($mailer =~ /elm$/)
	{
	    $command = $mailer;
	    $command .= " $email -s \"$subject\" < $mailfile";
	    system($command);
	}
    }

} # send_the_actual_mail

=head1 REQUIRES

    SQLite::Work
    CGI

    Test::More

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the script.

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}


=head1 SEE ALSO

perl(1).

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen (RUBYKAT)
    perlkat AT katspace dot com
    http://www.katspace.com

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2005 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of SQLite::Work::CGI
__END__
