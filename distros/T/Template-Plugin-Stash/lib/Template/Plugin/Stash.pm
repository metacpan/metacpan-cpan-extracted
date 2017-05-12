=head1 NAME

Template::Plugin::Stash - expose the stash, ideal for I<Dumper>ing...

=head1 SYNOPSIS

    [% USE Stash %]
    [% USE Dumper Indent = 1%]
    <pre>[% Dumper.dump_html( Stash.stash() ) %]</pre>

=head1 DESCRIPTION

Instead of messing with C<< [% PERL %] >> blocks
to get at the stash, simply C<< [% USE Stash %] >>.

Output will look something like

    $VAR1 = {
        'global' => {},
        'var1' => 6666666,
        'var2' => {
        'e' => 'f',
        'g' => 'h',
        'a' => 'b',
        'c' => 'd'
        },
    };

which should be all you need.

=head1 SEE ALSO

L<Template::Plugin|Template::Plugin>,
L<Template::Plugin::Dumper|Template::Plugin::Dumper>.

=head1 BUGS/SUGGESTIONS/ETC

To report bugs/suggestions/etc, go to
E<lt>http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-StashE<gt>
or send mail to E<lt>bug-Template-Plugin-Stash#rt.cpan.orgE<gt>.

=head1 LICENSE

Copyright (c) 2003-2004 by D.H. (PodMaster). All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. The LICENSE file contains the full
text of the license.

=cut

package Template::Plugin::Stash;
use strict;
use base qw[ Template::Plugin ];
use vars '$VERSION';
$VERSION = sprintf "%d.%03d", q$Revision: 1.6 $ =~ /(\d+).(\d+)/g;


sub new {
    my( $class, $con )  = @_;
    return bless { _CONTEXT => $con }, $class;
}

sub stash {
    my $self = shift;
    my $stash = { %{ $self->{_CONTEXT}->stash() } }; # do clone as Template::Stash does it

    delete $stash->{$_}
        for
            qw[ template dec inc component Stash ],
            grep { /^_/ } keys %$stash;
    
    for my $k( keys %$stash ){
        delete $stash->{$k}  if ref($stash->{$k}) =~ /^\QTemplate::Plugin/;
    }

    return $stash;
}

1;
