#!/usr/bin/perl
use warnings;
use strict;
{
    package OOP::Perlish::Class::Multiton;
    use OOP::Perlish::Class::Singleton;
    use base qw(OOP::Perlish::Class::Singleton);
    use Scalar::Util qw(blessed);

    sub _multiton_key(@) { return '___STUB___' }

    sub _singleton(@)
    {
        my ($self, %opts) = @_;
        my $class = ref($self) || $self;

        my $multiton_name = $opts{$self->_multiton_key()} if( exists( $opts{$self->_multiton_key()} ) );
        return unless($multiton_name);


        no strict 'refs';
        ${ $class . '::____MULTITON_REFS' } = {} unless(defined(${ $class . '::____MULTITON_REFS' }) && ref(${ $class . '::____MULTITON_REFS' }) eq 'HASH');
        my $multiton_refs = ${ $class . '::____MULTITON_REFS' };
        use strict 'refs';


        if( defined($multiton_refs) && ref($multiton_refs) eq 'HASH' && exists( $multiton_refs->{$multiton_name} ) && blessed( $multiton_refs->{$multiton_name} ) ) {
            $self->debug( 'Singleton of ' . $class . ' for key ' . $multiton_name . ' already initialized; NOT reinitialized!!' ) if( scalar keys %opts > 1 );
            return $multiton_refs->{$multiton_name};
        }
        else {
            $multiton_refs->{$multiton_name} = $class->new( %opts, _____oop_perlish_class__initialize_singleton => 1 );
            return $multiton_refs->{$multiton_name};
        }
        return;
    }
}
1;

=head1 NAME
=head1 VERSION
=head1 SYNOPSIS
=head1 EXPORT
=head1 FUNCTIONS
=head1 AUTHOR
=head1 BUGS
=head1 SUPPORT
=head1 ACKNOWLEDGEMENTS
=head1 COPYRIGHT & LICENSE
