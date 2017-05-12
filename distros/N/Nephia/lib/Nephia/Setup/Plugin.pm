package Nephia::Setup::Plugin;
use strict;
use warnings;

sub new { 
    my ($class, %opts) = @_;
    bless {%opts}, $class;
}

sub setup {
    my $self = shift;
    return $self->{setup};
}

sub fix_setup {
    my ($self) = @_;
}

sub bundle {
    return ();
}

1;

__END__

=encoding utf-8

=head1 NAME

Nephia::Setup::Plugin - Base class of plugin for Nephia::Setup

=head1 DESCRIPTION

If you want to create a new plugin for Nephia::Setup, inherit this class.

=head1 SYNOPSIS

    package Nephia::Setup::Plugin::MyWay;
    use parent 'Nephia::Setup::Plugin';
    
    sub fix_setup {
        my $self = shift;
        $self->SUPER::fix_setup;
        my $setup = $self->setup;
        my $chain = $setup->action_chain;
        ### append feature here
        ...
    }
    sub bundle { qw/ Foo Bar / } ### bundle "Nephia::Setup::Plugin::Foo" and "Nephia::Setup::Plugin::Bar"

=head1 METHODS

=head2 new

Constructor.

=head2 setup

Returns a Nephia::Setup instance.

=head2 fix_setup

You have to override this method if you want to append some action to Nephia::Setup.

=head2 bundle 

Returns array that contains bundled setup-plugins.

You may override this method when you want to bundle other setup-plugins.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

