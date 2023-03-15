package OpenAI::API::RequestDispatcherRole;

use Moo::Role;
use strictures 2;
use namespace::clean;

my %module_dispatcher = (
    chat           => 'OpenAI::API::Request::Chat',
    completions    => 'OpenAI::API::Request::Completion',
    edits          => 'OpenAI::API::Request::Edit',
    embeddings     => 'OpenAI::API::Request::Embedding',
    files          => 'OpenAI::API::Request::File::List',
    file_retrieve  => 'OpenAI::API::Request::File::Retrieve',
    image_create   => 'OpenAI::API::Request::Image::Generation',
    models         => 'OpenAI::API::Request::Model::List',
    model_retrieve => 'OpenAI::API::Request::Model::Retrieve',
    moderations    => 'OpenAI::API::Request::Moderation',
);

for my $sub_name ( keys %module_dispatcher ) {
    my $module = $module_dispatcher{$sub_name};

    eval "require $module";

    no strict 'refs';
    *{"OpenAI::API::RequestDispatcherRole::$sub_name"} = sub {
        my ( $self, %params ) = @_;
        my $request = $module->new( \%params );
        return $request->send($self);
    };
}

1;
