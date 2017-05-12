use strict;
use warnings;

package Sub::Exporter::Simple;
BEGIN {
  $Sub::Exporter::Simple::VERSION = '1.103210';
}

# ABSTRACT: just export some subs

use Sub::Exporter 'setup_exporter';

sub import {
    my ( $self, @subs ) = @_;
    return setup_exporter( { exports => [ @subs ], into_level => 1 } );
}

1;


__END__
=pod

=head1 NAME

Sub::Exporter::Simple - just export some subs

=head1 VERSION

version 1.103210

=head1 SYNOPSIS

In your module:

    package Module;

    use Sub::Exporter::Simple qw( function1 function2 function3 );

    function1 { 1 }
    function2 { 2 }
    function3 { 3 }

In your target:

    use Module qw( function1 );

    function1();

=head1 DESCRIPTION

This module is basically just a macro for:

    use Sub::Exporter -setup => { exports => [ qw( function1 function2 function3 ) ] };

I made it because i found myself in the situation of wanting to simply export some subs in a number of modules, but not
wanting to use L<Exporter>, since L<Sub::Exporter> offers a nicer API. However the default way of just exporting some
plain subs in Sub::Exporter is a bit cumbersome to type (especially repeatedly) and does not look very clean either.
(As far as typing effort goes, please do consider that [] and friends are often AltGr affairs in non-american layouts.)
So this module just acts as a macro for that functionality and reduces the amount of needed typing, while making things
look more clean.

That's all it does. It does not expose any other functionality of L<Sub::Exporter> and never will. If you need more than
this, use the real thing.

=head1 THANKS

Thanks to rjbs for writing the excellent L<Sub::Exporter> and providing some input for this module, as well as catching
a bug before the first release.

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>. I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 AUTHOR

Christian Walde <mithaldu@yahoo.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Christian Walde.

This is free software, licensed under:

  DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

=cut

