package MooseX::Role::Cmd::Meta::Attribute::Trait;
use Moose::Role;
use Moose::Util::TypeConstraints;

=pod

=head1 NAME

MooseX::Role::Cmd::Meta::Attribute::Trait - Optional meta attribute trait for custom option names

=head1 SYNOPSIS

    package MyApp::Cmd::SomeScript;
    
    with 'MooseX::Role::Cmd';
    
    has 'basic'   => (
        isa             => 'Str',
        is              => 'rw',
    );
    
    has 'prefix'   => (
        traits          => [ 'CmdOpt' ],
        isa             => 'Str',
        is              => 'rw',
        cmdopt_prefix   => '-',
    );
    
    has 'rename'   => (
        traits          => [ 'CmdOpt' ],
        isa             => 'Str',
        is              => 'rw',
        cmdopt_name     => '+alt_name',
    );
    
    
    $cmd = MyApp::Cmd::SomeScript->new( basic => 'foo', prefix => 'bar', rename => 'foobar' );
    
    $cmd->run();
    
    # somescript --basic foo -prefix bar +alt_name foobar

=head1 DESCRIPTION

Provides some extra markup to help MooseX::Role::Cmd decide how to use command line parameters.

=head1 ATTRIBUTES

=head2 cmdopt_prefix

Forces the command prefix to be a certain character. This was introduced to allow
parameters to be specified as "-param" or "--param"

=head2 has_cmdopt_prefix

Test for attribute above

=cut

has 'cmdopt_prefix' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_cmdopt_prefix',
);

=head2 cmdopt_name

Forces the command options name to be the passed string. This was introduced to allow
parameters to have a different name to the attribute.

This option will override the L<cmdopt_prefix> attribute.

=head2 has_cmdopt_name

Test for attribute above

=cut

has 'cmdopt_name' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_cmdopt_name',
);

=head2 cmdopt_env

This attribute trait can be used to specify an environment variable rather
than a command line option.

    has 'home_dir' => (
        traits => [ 'CmdOpt' ],
        is => 'rw',
        isa => 'Str',
        cmdopt_env => 'APP_HOME',
        default => '/my/app/home'
    );
    
    # $ENV{APP_HOME} = /my/app/home

=cut

=head2 has_cmdopt_env

Test for attribute above

=cut

has 'cmdopt_env' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_cmdopt_env',
);

no Moose::Role;

# register this as a metaclass alias ...
package # stop confusing PAUSE 
    Moose::Meta::Attribute::Custom::Trait::CmdOpt;
sub register_implementation { 'MooseX::Role::Cmd::Meta::Attribute::Trait' }

1;

__END__

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Ian Sillitoe E<lt>ian.sillitoe@gmail.comE<gt>

=head1 SEE ALSO

The idea for this code was ripped kicking and screaming from L<MooseX::Getopt::Meta::Attribute::Trait>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
