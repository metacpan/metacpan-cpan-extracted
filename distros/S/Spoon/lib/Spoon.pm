package Spoon;
use Spoon::Base -Base;
our $VERSION = '0.24';

const class_id => 'main';

sub load_hub {
    $self->destroy_hub;
    my $hub = $self->hub(@_);
    $hub->main($self);
    $self->init;
    return $hub;
}

__END__

=head1 NAME

Spoon - A Spiffy Application Building Framework

=head1 SYNOPSIS

    Out of the Cutlery Drawer
    And onto the Dinner Table

=head1 DESCRIPTION

Spoon is an Application Framework that is designed primarily for
building Social Software web applications. The Kwiki wiki software is
built on top of Spoon.

Spoon::Base is the primary base class for all the Spoon::* modules.
Spoon.pm inherits from Spiffy.pm.

Spoon is not an application in and of itself. (As compared to Kwiki)
You need to build your own applications from it.

=head1 SEE ALSO

Kwiki, Spork, Spiffy, IO::All

=head1 DEDICATION

This project is dedicated to the memory of Iain "Spoon" Truskett.

=head1 CREDIT

Dave Rolsky and Chris Dent have made major contributions to this code
base. Of particular note, Dave removed the memory cycles from the hub
architecture, allowing safe use with mod_perl.

(Dave, Chris and myself currently work at Socialtext, where this
framework is heavily used.)

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.
Copyright (c) 2006. Ingy döt Net. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
