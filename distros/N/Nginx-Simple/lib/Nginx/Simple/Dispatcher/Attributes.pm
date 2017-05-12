use attributes;
use warnings;
use strict;

package Nginx::Simple::Dispatcher::Attributes;

=head1 NAME 

Nginx::Simple::Dispatcher::Attributes

Attributes:
Index, Page

=head1 Synopsis

Code attributes.

=head1 Methods

=cut

our ( %dispatch_flags, %cached_flags );

sub MODIFY_CODE_ATTRIBUTES
{
    my ($pack, $ref, @attr) = @_;

    for my $attr ( @attr ) {

        # ensure a $dispatch_flags{$pack} hashref, always
        $dispatch_flags{$pack} = { }
            unless exists $dispatch_flags{$pack};

        if  ($attr eq 'Index')
        {
            $dispatch_flags{$pack}{$ref} = 'index';
        }
        if  ($attr eq 'Action')
        {
            $dispatch_flags{$pack}{$ref} = 'action';
        }
        elsif  ($attr =~ /^Path/)
        {
            my $desc;
            $desc = $1 if $attr =~ /\((.*?)\)$/;

            $dispatch_flags{$pack}{$ref} = "$desc";
       }
    }

    return ();
}

sub FETCH_CODE_ATTRIBUTES { $dispatch_flags{shift}{shift} }

=head2 get_dispatch_flags

Returns all autoflags specific to a package with inheritance.

=cut

sub get_dispatch_flags
{
    my $self  = shift;
    my $class = ref $self ? ref $self : $self;

    $cached_flags{$class} = $class->get_package_dispatch_flags
        unless exists $cached_flags{$class};

    return $cached_flags{$class};
}

=head2 get_package_dispatch_flags

Get autoflags, only specific to the called package.

=cut

sub get_package_dispatch_flags
{
    my $self      = shift;
    my $class     = ref $self ? ref $self : $self;
    my @code_refs = keys %{$dispatch_flags{$class}};

    my %flag_methods;
    {
        no strict 'refs';
        for my $key (keys %{"${class}::"})
        {
            my $code_ref = "${class}::${key}";

            if (defined &$code_ref)
            {
                my $code = \&$code_ref;

                $flag_methods{"$key"} = $dispatch_flags{"$class"}{"$code"}
                    if grep { "$code" eq "$_" } @code_refs;
            }
        }
    }

    return \%flag_methods;
}

=head1 Author

Michael J. Flickinger, C<< <mjflick@gnu.org> >>

=head1 Copyright & License

You may distribute under the terms of either the GNU General Public
License or the Artistic License.

=cut

1;

