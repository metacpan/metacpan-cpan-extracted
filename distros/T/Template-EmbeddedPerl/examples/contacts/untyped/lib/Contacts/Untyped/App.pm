package Contacts::Untyped::App;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Spec;
use Template::EmbeddedPerl;

sub new {
    my ($class, %args) = @_;
    my $root = $args{root} || File::Spec->rel2abs(
        File::Spec->catdir(dirname(__FILE__), qw(.. .. ..)),
    );

    my $self = bless {
        root => $root,
        heading_calls => 0,
    }, $class;

    $self->{engine} = Template::EmbeddedPerl->new(
        directories => [File::Spec->catdir($root, 'templates')],
        smart_lines => 1,
        auto_escape => 1,
        use_cache => 1,
        helpers => {
            display_heading => sub {
                my ($engine, $value) = @_;
                $self->{heading_calls}++;
                return uc $value;
            },
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

sub heading_calls { $_[0]->{heading_calls} }

sub render {
    my ($self, %args) = @_;
    return $self->{engine}->from_file('pages/contacts')->render(
        contacts => $self->contacts,
        %args,
    );
}

1;
