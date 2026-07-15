package Contacts::Typed::App;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Spec;
use Template::EmbeddedPerl;
use Contacts::Typed::View::HTML::ContactList;
use Contacts::Typed::View::HTML::Badge;

sub new {
    my ($class, %args) = @_;
    my $root = $args{root} || File::Spec->rel2abs(
        File::Spec->catdir(dirname(__FILE__), qw(.. .. ..)),
    );

    my $self = bless {
        root => $root,
        factory_calls => [],
    }, $class;

    $self->{engine} = Template::EmbeddedPerl->new(
        directories => [File::Spec->catdir($root, 'templates')],
        smart_lines => 1,
        auto_escape => 1,
        use_cache => 1,
        view_namespace => 'Contacts::Typed::View',
        helpers => {
            display_heading => sub {
                my ($engine, $value) = @_;
                return uc $value;
            },
        },
        view_factory => sub {
            my ($class, $values, $context) = @_;
            my $view = $class->new(
                %$values,
                root => $context->root_view,
                parent => $context->view,
            );
            push @{$self->{factory_calls}}, {
                class => $class,
                args => {%$values},
                context => $context,
                view => $view,
            };
            return $view;
        },
    );

    return $self;
}

sub contacts {
    return [
        {name => '<Ada>', email => 'ada@example.test'},
        {name => 'Grace', email => 'grace@example.test'},
    ];
}

sub root_view { $_[0]->{root_view} }
sub factory_calls { $_[0]->{factory_calls} }

sub render {
    my ($self) = @_;
    $self->{factory_calls} = [];
    my $contacts = $self->contacts;
    $self->{root_view} = Contacts::Typed::View::HTML::ContactList->new(
        title => 'Contacts',
        contacts => $contacts,
        prebuilt_badge => Contacts::Typed::View::HTML::Badge->new(
            label => scalar(@$contacts) . ' contacts',
        ),
    );
    return $self->{engine}->render_view($self->{root_view});
}

1;
