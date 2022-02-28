##----------------------------------------------------------------------------
## Module Generic - ~/lib/Class.pm
## Version v1.1.2
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/02/27
## Modified 2022/02/27
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Class;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    # Faster than 'use constant'.  Load time critical.
    # Must eval to make $] constant.
    *PERL_VERSION = eval qq{ sub () { $] } };
    our $VERSION = 'v1.1.2';
};

sub import
{
    my $self = shift( @_ );
    my $pkg = caller;
    *{$pkg . '::CLASS'} = \$pkg;

    # This logic is compiled out.
    if( PERL_VERSION >= 5.008 )
    {
        # 5.8.x smart enough to make this a constant.
        # For legacy, we keep the upper case subroutine as well
        *{$pkg . '::CLASS'} = sub () { $pkg };
    }
    else
    {
        # Make CLASS a constant.
        *{$pkg . '::CLASS'} = eval qq{ sub () { q{$pkg} } };
    }
    
    local $Exporter::ExportLevel = 1;
    Exporter::import( $self, @_ );
    
    ( my $dir = $pkg ) =~ s/::/\//g;
    my $path  = $INC{ $dir . '.pm' };
    if( defined( $path ) )
    {
        ## Try absolute path name
        $path =~ s/^(.*)$dir\.pm$/$1auto\/$dir\/autosplit.ix/;
        eval
        {
            local $SIG{ '__DIE__' }  = sub{ };
            local $SIG{ '__WARN__' } = sub{ };
            require $path;
        };
        if( $@ )
        {
            $path = "auto/$dir/autosplit.ix";
            eval
            {
                local $SIG{ '__DIE__' }  = sub{ };
                local $SIG{ '__WARN__' } = sub{ };
                require $path;
            };
        }
        if( $@ )
        {
            CORE::warn( $@ ) unless( $SILENT_AUTOLOAD );
        }
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Class - A Generic Object Class to Inherit From

=head1 SYNOPSIS

    use parent qw( Class );
    
    sub init
    {
        my $self = shift( @_ );
        return( $self->SUPER::init( @_ ) );
    }

Support for legacy code:

    package Foo;
    use Class;

    print CLASS;                  # Foo
    print "My class is $CLASS\n"; # My class is Foo

    sub bar { 23 }

    print CLASS->bar;     # 23
    print $CLASS->bar;    # 23

=head1 VERSION

    v1.1.2

=head1 DESCRIPTION

This package inherits all its features from L<Module::Generic> and provides a generic framework of methods to inherit from and speed up development.

It also provide support for legacy code whereby C<CLASS> and C<$CLASS> are both synonyms for C<__PACKAGE__>.  Easier to type.

C<$CLASS> has the additional benefit of working in strings.

C<Class> is a constant, not a subroutine call. C<$CLASS> is a plain variable, it is not tied. There is no performance loss for using C<Class> over C<__PACKAGE__> except the loading of the module. (Thanks Juerd)

=head1 SEE ALSO

L<Class::Stack>, L<Class::String>, L<Class::Number>, L<Class::Boolean>, L<Class::Assoc>, L<Class::File>, L<Class::DateTime>, L<Class::Exception>, L<Class::Finfo>, L<Class::NullChain>

=head1 AUTHOR

From February 2022 onward: Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

Michael G Schwern E<lt>F<schwern@pobox.com>E<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
