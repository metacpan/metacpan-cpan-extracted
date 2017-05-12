package Object::Quick;
use strict;
use warnings;

use Mock::Quick::Object;
use Mock::Quick::Method;
use Mock::Quick::Util;
use Carp qw/croak carp/;


sub import {
    carp "Object::Quick is depricated, use Mock::Quick instead.";
    my $class = shift;
    my $caller = caller;
    my ( @names, %args );
    for my $i ( @_ ) {
        if( $i =~ m/^-/ ) {
            $args{$i}++;
        }
        else {
            push @names => $i;
        }
    }

    if ( $args{'-obj'} ) {
        $names[0] ||= 'obj';
        $names[1] ||= 'method';
        $names[2] ||= 'clear';
    }

    croak <<EOT if $args{'-class'};
'-class' is no longer supported as of V1.0
if you use this functionality send me an email at exodist7\@gmail.com
I will add it in.
EOT

    inject( $caller, $names[0], sub { Mock::Quick::Object->new( @_ )}) if $names[0];
    inject( $caller, $names[1], sub(&) { Mock::Quick::Method->new( @_ )}) if $names[1];
    inject( $caller, $names[2], sub { \$Mock::Quick::Util::CLEAR }) if $names[2];
}

1;

__END__

=head1 NAME

Object::Quick - Depricated, see L<Mock::Quick>

=head1 DESCRIPTION

Legacy interface to L<Mock::Quick>

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2011 Chad Granum

Mock-Quick is free software; Standard perl licence.

Mock-Quick is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the license for more details.
