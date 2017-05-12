package MooseX::Runnable::Invocation::Plugin::Profile;

our $VERSION = '0.10';

use Moose::Role;
use namespace::autoclean;

before 'load_class' => sub {
    my ($self) = @_;
    confess 'The Profile plugin cannot be used when not invoked via mx-urn'
      unless $self->does('MooseX::Runnable::Invocation::Role::WithParsedArgs');

    my @cmdline = $self->parsed_args->guess_cmdline(
        perl_flags      => ['-d:NYTProf'],
        without_plugins => ['Profile', '+'.__PACKAGE__],
    );

    eval { $self->_debug_message(
        "Re-execing with ". join ' ' , @cmdline,
    )};

    exec(@cmdline);
};

1;
