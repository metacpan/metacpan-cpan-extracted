package Railsish::View::tt2;
our $VERSION = '0.21';


use Any::Moose;
extends 'Railsish::View';

use Template;

sub render {
    my ($self, %vars) = @_;

    unless (exists $vars{layout}) {
        $vars{layout} = "layouts/application.html.tt2";
    }

    my $template_config = {
        INCLUDE_PATH => [ $self->template_root ],
        PROCESS => $vars{layout},
        ENCODING => 'utf8'
    };

    delete $template_config->{PROCESS} unless defined $vars{layout};

    my $tt = Template->new($template_config);

    for (@Railsish::ViewHelpers::EXPORT) {
	$vars{$_} = \&{"Railsish::ViewHelpers::$_"};
    }

    my $output = "";
    $tt->process($vars{file}, \%vars, \$output)
	|| die $tt->error();

    return $output;
}

__PACKAGE__->meta->make_immutable;

__END__
=head1 NAME

Railsish::View::tt2

=head1 VERSION

version 0.21

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

