package PerlX::QuoteOperator::URL;
use strict;
use warnings;
use PerlX::QuoteOperator ();
use LWP::Simple ();

our $VERSION = '1.02';

sub import {
    my ($class, $name) = @_;
    
    my $caller = caller;
    my $code   = sub ($) { LWP::Simple::get( $_[0] ) };

    my $ctx = PerlX::QuoteOperator->new;
    $ctx->import( $name || 'qURL', { -emulate => 'qq', -with => $code }, $caller );
}

1;

__END__

=encoding utf-8

=head1 NAME

PerlX::QuoteOperator::URL - Quote-like operator returning http request for the URL provided.

=head1 VERSION

Version 1.02

=head1 SYNOPSIS

    use PerlX::QuoteOperator::URL;

    my $content = qURL( http://transfixedbutnotdead.com );   # does HTTP request


=head1 DESCRIPTION

This module provides a Quote-like operator which returns a HTTP request using the  LWP::Simple module.

Please see L<PerlX::QuoteOperator> for more detail on Quote-like operators.

For now here is another example:

    use PerlX::QuoteOperator::URL 'qh';
    use JSON qw(decode_json);

    say decode_json( qh{ http://twitter.com/statuses/show/6592721580.json } )->{text};

    # => "He nose the truth."
    

=head1 EXPORT

By default 'qURL' is exported to calling package/program.

This can be changed by providing a name of your own choice:

    use PerlX::QuoteOperator::URL 'q_http_request';
    

=head1 FUNCTIONS

=head2 import

Standard import subroutine.


=head1 SEE ALSO

NB. This module use to be part of the PerlX::QuoteOperator distro.  It was removed at 0.05 (23rd Feb 2015)

=over 4

=item * L<PerlX::QuoteOperator>

=item * L<Acme::URL>

=item * L<http://transfixedbutnotdead.com/2009/12/16/url-develdeclare-and-no-strings-attached/>

=item * L<http://transfixedbutnotdead.com/2009/12/26/couple-of-cpan-pressies/>

=back


=head1 CONTRIBUTORS

Brian Rossmajer (https://github.com/BrianRossmajer) for Directory::Scratch removal patch at 1.01



=head1 AUTHOR

Barry Walsh, C<< <draegtun at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/draegtun/PerlX-QuoteOperator-URL/issues>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PerlX::QuoteOperator::URL


You can also look for information at:

=over 4

=item * Github issues and pull requests

L<https://github.com/draegtun/PerlX-QuoteOperator-URL/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PerlX-QuoteOperator-URL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PerlX-QuoteOperator-URL>

=item * Search CPAN

L<http://search.cpan.org/dist/PerlX-QuoteOperator-URL/>

=back


=head1 ACKNOWLEDGEMENTS

Inspired by this blog post: L<http://ozmm.org/posts/urls_in_ruby.html> and wanting to learn L<Devel::Declare>


=head1 DISCLAIMER

This is (near) beta software.   I'll strive to make it better each and every day!

However I accept no liability I<whatsoever> should this software do what you expected ;-)

=head1 COPYRIGHT & LICENSE

Copyright 2015- Barry Walsh (Draegtun Systems Ltd | L<http://www.draegtun.com>), all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

