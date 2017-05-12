{
    package Hello;
    use Squatting;
}

{
    package Hello::Controllers;

    my $home = sub {
        my $self = shift;
        $self->v->{title} = "Hello world";
        $self->v->{message} = "Your name: " . $self->input->{name};
        $self->render('home');
    };
    our @C = (
        C( Home => ['/'],
           get => $home,
           post => $home ),
        C( Multi => ['/multi'],
           get => sub {
               my $self = shift;
               $self->{v}->{message} = join ",", @{$self->input->{'q'}};
               $self->render('home');
           } ),
    );
}
{
    package Hello::Views;

    our @V = (
        V(
            'html',
            layout => sub {
                my($self, $v, $content) = @_;
                "<html><head><title>$v->{title}</title></head>".
                "<body>$content</body></html>";
            },
            home => sub {
                my($self, $v) = @_;
                "<h1>$v->{message}</h1>",
            },
        ),
    );
}

1;
