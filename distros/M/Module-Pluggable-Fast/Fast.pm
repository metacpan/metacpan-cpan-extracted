package Module::Pluggable::Fast;

use strict;
use vars '$VERSION';
use UNIVERSAL::require;
use Carp qw/croak carp/;
use File::Find ();
use File::Basename;
use File::Spec::Functions qw/splitdir catdir abs2rel/;

$VERSION = '0.19';

=head1 NAME

Module::Pluggable::Fast - Fast plugins with instantiation

=head1 SYNOPSIS

    package MyClass;
    use Module::Pluggable::Fast
      name   => 'components',
      search => [ qw/MyClass::Model MyClass::View MyClass::Controller/ ];

    package MyOtherClass;
    use MyClass;
    my @components = MyClass->components;

=head1 DESCRIPTION

Similar to C<Module::Pluggable> but instantiates plugins as soon as they're
found, useful for code generators like C<Class::DBI::Loader>.

=head2 OPTIONS

=head3 name

Name for the exported method.
Defaults to plugins.

=head3 require

If true, only require plugins.

=head3 callback

Codref to be called instead of the default instantiate callback.

=head3 search

Arrayref containing a list of namespaces to search for plugins.
Defaults to the ::Plugin:: namespace of the calling class.

=cut 

sub import {
    my ( $class, %args ) = @_;
    my $caller = caller;
    no strict 'refs';
    *{ "$caller\::" . ( $args{name} || 'plugins' ) } = sub {
        my $self = shift;
        $args{search}   ||= ["$caller\::Plugin"];
        $args{require}  ||= 0;
        $args{callback} ||= sub {
            my $plugin = shift;
            my $obj    = $plugin;
            eval { $obj = $plugin->new(@_) };
            carp qq/Couldn't instantiate "$plugin", "$@"/ if $@;
            return $obj;
        };

        my %plugins;
        foreach my $dir ( exists $INC{'blib.pm'} ? grep { /blib/ } @INC : @INC )
        {
            foreach my $searchpath ( @{ $args{search} } ) {
                my $sp = catdir( $dir, ( split /::/, $searchpath ) );
                next unless ( -e $sp && -d $sp );
                foreach my $file ( _find_packages($sp) ) {
                    my ( $name, $directory ) = fileparse $file, qr/\.pm/;
                    $directory = abs2rel $directory, $sp;
                    my $plugin = join '::', splitdir catdir $searchpath,
                      $directory, $name;
                    $plugin->require;
                    my $error = $UNIVERSAL::require::ERROR;
                    die qq/Couldn't load "$plugin", "$error"/ if $error;

                    unless ( $plugins{$plugin} ) {
                        $plugins{$plugin} =
                            $args{require}
                          ? $plugin
                          : $args{callback}->( $plugin, @_ );
                    }

                    for my $class ( _list_packages($plugin) ) {
                        next if $plugins{$class};
                        $plugins{$class} =
                            $args{require}
                          ? $class
                          : $args{callback}->( $class, @_ );
                    }
                }
            }
        }
        return values %plugins;
    };
}

sub _find_packages {
    my $search = shift;

    my @files = ();

    my $wanted = sub {
        my $path = $File::Find::name;
        return unless $path =~ /\w+\.pm$/;
        return unless $path =~ /\A(.+)\z/;
        $path = $1;     # untaint

        # don't include symbolig links pointing into nowhere
        # (e.g. emacs lock-files)
        return if -l $path && !-e $path;
        $path =~ s#^\\./##;
        push @files, $path;
    };

    File::Find::find( { no_chdir => 1, wanted => $wanted }, $search );

    return @files;
}

sub _list_packages {
    my $class = shift;
    $class .= '::' unless $class =~ m!::$!;
    no strict 'refs';
    my @classes;
    for my $subclass ( grep !/^main::$/, grep /::$/, keys %$class ) {
        $subclass =~ s!::$!!;
        next if $subclass =~ /^::/;
        push @classes, "$class$subclass";
        push @classes, _list_packages("$class$subclass");
    }
    return @classes;
}

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Module::Pluggable>

=cut

1;
