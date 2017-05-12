package Template::Plugin::PerlTidy;
use strict;
use Template::Plugin::Filter;
use Perl::Tidy;
use base qw( Template::Plugin::Filter );
use vars qw($VERSION);

$VERSION = 0.03;

use vars qw( $DYNAMIC );
$DYNAMIC = 1;

=pod

=head1 NAME

Template::Plugin::PerlTidy - Perl::Tidy filter for Template Toolkit

=head1 SYNOPSIS

 # HTML Syntax Coloring, no reformatting

 [% USE PerlTidy 'html' 'nnn' 'pre' %]
 [% FILTER $PerlTidy %]
   #!/usr/bin/perl -w
   use strict;
   my@foo=(1,2,'a',4);
   for(1,3,5){print" $_\n"}my     %hash =( 1=>'foo',foo=>'bar',);
 [% END %]


 # Chained filter, code reformatting and syntax coloring

 [%- USE PerlTidy -%]
 [%- FILTER $PerlTidy 'html' 'nnn' -%]
    [%- FILTER $PerlTidy i=10 -%]
       ... perl code goes here ... 
    [%- END -%]
 [%- END -%]

=head1 DESCRIPTION

This modules is a Template Toolkit Filter for Perl::Tidy. It can be used
to automatically display coloured and formatted perl code in web pages.

=head1 OPTIONS

All the options available in perltidy should be also available in
this plugin.

The options defined in Perl::Tidy::perltidy() are also supported
(C<stderr>, C<perltidyrc>, C<logfile>, C<errorfile>). The C<source> and
<destination> options are handled by the filter.

By default, the C<quiet> option is turned on, but you can disable it 
using the C<verbose> option.

Note that options which does not take any arguments (like -html or -pre)
should be enclosed in quotes (i.e. C<[% USE PerlTidy 'html' %]>), and
options which take an argument are not enclosed in quotes (i.e. C<[% USE
PerlTidy i=8 %]>).

=cut

sub filter {
    my ( $self, $text, $args, $conf ) = @_;

    $args = $self->merge_args($args);
    $conf = $self->merge_config($conf);

    my %options = %{$conf};

    my ( $stderr, $perltidyrc, $logfile, $errorfile ) =
      @options{qw( stderr perltidyrc logfile errorfile )};

    delete @options{qw( stderr perltidyrc logfile errorfile )};

    foreach my $args ( @{$args} ) {
        $options{$args} = undef unless exists $options{$args};
    }

    my $argv;
    foreach my $key ( keys %options ) {
		next if $key eq 'verbose';
        $argv .= $options{$key} ? qq' -$key="$options{$key}"' : " -$key";
    }

	if ( ! exists $options{verbose} ){
		$argv .= ' -q'; # be quiet by default
	}
	
    my $formated;
    perltidy(
        source      => \$text,
        destination => \$formated,
        argv        => $argv,
        stderr      => $stderr,
        perltidyrc  => $perltidyrc,
        logfile     => $logfile,
        errorfile   => $errorfile,
    );

    return $formated;
}

1;

__END__

=pod

=head1 BUGS

Please report any bugs or comments using the Request Tracker interface:
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template%3A%3APlugin%3A%3APerlTidy>

=head1 AUTHOR

Briac Pilpré <briac@cpan.org>

Thanks to Steve Hancock for PerlTidy

Thanks to BooK and echo for their help.


=head1 COPYRIGHT

This module is distributed under the same terms as perl itself.

=head1 SEE ALSO

Template::Plugin::Filter, Perl::Tidy

=cut

