package App::Prove::Plugin::HTML;

=head1 NAME

App::Prove::Plugin::HTML - a prove plugin for HTML output

=head1 SYNOPSIS

 # command-line usage:
 prove -m -P HTML=outfile:out.html,css_uri:style.css,js_uri:foo.js,force_inline_css:0

 # NOTE: this is currently in alpha, this usage will likely change!

=cut

use strict;
use warnings;

use TAP::Formatter::HTML;

our $VERSION = '0.13';

sub import {
    my ($class, @args) = @_;
    # deprecated, do nothing
    return $class;
}

sub load {
    my ($class, $p) = @_;
    my @args = @{ $p->{args} };
    my $app  = $p->{app_prove};

    # parse the args
    my %TFH_args;
    foreach my $arg (@args) {
	my ($key, $val) = split(/:/, $arg, 2);
	if (grep {$key eq $_} qw(css_uri js_uri)) {
	    push @{ $TFH_args{$key . 's'}}, $val;
	} else {
	    $TFH_args{$key} = $val;
	}
    }

    # set the formatter to use
    $app->formatter( 'TAP::Formatter::HTML' );

    # set ENV vars in order to pass args to TAP::Formatter::HTML
    # horrible, but it's currently the only way :-/
    while (my ($key, $val) = each %TFH_args) {
	$val = join( ':', @$val ) if (ref($val) eq 'ARRAY');
	$ENV{"TAP_FORMATTER_HTML_".uc($key)} = $val;
    }

    # we're done
    return $class;
}


1;

__END__

=head1 DESCRIPTION

This is a quick & dirty second attempt at making L<TAP::Formatter::HTML> easier
to use from the command line.  It will change once L<App::Prove> has better
support for plugins than need to take cmdline data.

The original goal was to be able to specify all the args on the cmdline, ala:

  prove --html=output.html --css-uri foo.css --css-uri bar.css --force-inline-css 0

But this is currently not possible with the way the L<App::Prove> plugin system
works.

As a compromise, you must use the following syntax:

  prove -P HTML=arg1:val1,arg2:val2,...

Where I<argN> is any L<TAP::Formatter::HTML> parameter that is configurable via
C<%ENV>.

=head2 Example

  prove -P HTML=outfile:out.html,css_uri:style.css,js_uri:foo.js,force_inline_css:0

This will cause L<prove> to load this plugin, which loads L<TAP::Formatter::HTML>
for you, and sets I<formatter> to C<TAP::Formatter::HTML> to save you some typing.

To configure L<TAP::Formatter::HTML>, the following C<%ENV> vars are set:

  TAP_FORMATTER_HTML_OUTFILE=out.html
  TAP_FORMATTER_HTML_FORCE_INLINE_CSS=0
  TAP_FORMATTER_HTML_CSS_URIS=style.css
  TAP_FORMATTER_HTML_JS_URIS=func.js

Yes, you can pass 2 or more I<css_uri> or I<js_uri> args.

=head2 %ENV vars?!

Briefly, L<App::Prove> currently only lets you specify the C<formatter_class> for
L<TAP::Harness>, it doesn't let you instantiate a formatter, or pass config to
the formatter.

I<Yes, I know %ENV vars are a horrible way to do things.>  If it bugs you too,
then join the L<TAP::Harness> devs and help us fix it ;-).

=head1 BUGS

Please use http://rt.cpan.org to report any issues.

=head1 AUTHOR

Steve Purkis <spurkis@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2008-2010 Steve Purkis <spurkis@cpan.org>, S Purkis Consulting Ltd.
All rights reserved.

This module is released under the same terms as Perl itself.

=head1 SEE ALSO

L<prove>, L<App::Prove>, L<TAP::Formatter::HTML>

=cut
