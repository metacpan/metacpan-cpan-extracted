package Objects::Collection::LazyObject;

=head1 NAME

Objects::Collection::Object - Lazy call.

=head1 SYNOPSIS

    use Objects::Collection::Object;
    my $lazy = new Objects::Collection::LazyObject:: 
            sub { new SomeClass:: %attr };

=head1 DESCRIPTION

Lazy call.

=cut

use strict;
use warnings;
use strict;
use Carp;
$Objects::Collection::LazyObject::VERSION = '0.01';
no strict 'refs';
### install get/set accessors for this object.
for my $key (qw/   ___sub_ref___  ___obj_ref___ /) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$key" } = sub {
        my $self = shift;
        $self->{$key} = $_[0] if @_;
        return $self->{$key};
      }
}

sub new {
    my $class = shift;
    $class = ref $class if ref $class;
    my $self = bless( {}, $class );
    $self->___sub_ref___(shift) || return;
    $self;
}

sub ___get_object___ {
    my $self = shift;
    my $obj  = $self->___obj_ref___;
    unless ($obj) {
        $obj = $self->___sub_ref___->()
          || die "can't do lazy call. need result";
        $self->___obj_ref___($obj);
    }
    $obj;
}

sub AUTOLOAD {
    my $self = shift;
    return if $Objects::Collection::LazyObject::AUTOLOAD =~ /::(DESTROY)$/;
    ( my $auto_sub ) = $Objects::Collection::LazyObject::AUTOLOAD =~ /.*::(.*)/;
    return $self->___get_object___->$auto_sub(@_);

}

1;
__END__


=head1 SEE ALSO

Objects::Collection::ActiveRecord, Objects::Collection, README

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

