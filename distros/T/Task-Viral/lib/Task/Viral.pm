package Task::Viral;
use strict;
use warnings;

our $VERSION = '0.02.1';

1;

=encoding utf8

=head1 NAME

Task::Viral - Conquer hosts with a camel

=head1 DESCRIPTION

This bundle includes all the stuff you need to build a chain of hosts with Perl installed and CPAN modules you need updated, including your private packages.

=head2 WHAT IS AN HOST CHAIN?

Suppose you have the following topology.

    Internet <-- host-1 <-- host-2 <-- ... <-- host-N

where C<host-i> are, for instance, under C<.example.org> domain.

Here I call an B<host chain> an array of hosts, where C<host-0> is some active CPAN mirror on Internet.

The C<host-(i+1)> can connect to C<host-i> and use it as CPAN mirror.

For example, an B<host chain> could be

    www.cpan.org <-- development.example.org <-- test.example.org <-- production.example.org

where test and production hosts perhaps could not connect to Internet.

=head2 SETUP FIRST HOST CHAIN

=over 4

=item 1

Start from C<development>, launch

    cpan Task::Viral

=item 2

Create folders for L<mcpani>

    mkdir -p $HOME/.mcpani/local
    mkdir -p $HOME/.mcpani/private

and write C<$HOME/.mcpani/config> configuration

    cat <<EOF > $HOME/.mcpani/config
    local: $HOME/.mcpani/local
    remote: http://www.cpan.org
    repository: $HOME/.mcpani/private
    passive: yes
    dirmode: 0755
    EOF

Create your mirror

    mcpani --mirror -v

=item 3

Configure L<cpan> to install from local mirror

    cpan> o conf urllist file://home/user/.mcpani/local
    cpan> o conf commit

=back

=head2 SETUP THE WHOLE HOST CHAIN

Start from C<development>.

=over 4

=item 1

Launch a L<cpanmirrorhttpd> to serve installed packages to C<test>, for instance on port C<2000>

    cpanmirrorhttpd --root $HOME/.cpan/sources  --port 2000

=item 2

Login into C<test> and configure L<cpan> to install packages from C<development>.

    cpan> o conf urllist http://development.example.org:2000
    cpan> o conf commit

Now you can launch

    cpan Task::Viral

=back

and iterate steps on C<host-(i+1)> until last element in the C<host chain>, in this case C<production>.

=head2 ADD YOUR PRIVATE DISTROS

Suppose you create some distro on development host, for instance C<My::Package>.
You may want to install it on test host as usual

    cpan My::Package

To add your private distros to your B<host chain>,

Create your distro tarball, for instance C<My-Package-0.01.tar.gz>, and inject it in your local CPAN

    mcpani  --add --module My::Package --authorid AUTHOR --modversion 0.01 --file ./My-Package-0.01.tar.gz

Inject your module

    mcpani --inject -v

=head1 STUFF INCLUDED

=over 4

=item *

L<CPAN>

=item *

L<CPAN::Mirror::Server::HTTP>

=item *

L<CPAN::Mini::Inject>

=back

=head1 SEE ALSO

L<Private CPAN Distributions|http://www.drdobbs.com/web-development/private-cpan-distributions/184416190> article by L<https://metacpan.org/author/BDFOY|BDFOY>.

=head1 COPYRIGHT AND LICENSE

This software is copyright © III Millenium by L<G. Casati|http://g14n.info>.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

