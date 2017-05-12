package Sledge::Template::Xslate;

use strict;
use warnings;

our $VERSION = '0.09';
our $XSLATE_CACHE_DIR_NAME = 'xslate';

use parent qw(Sledge::Template);

use Text::Xslate;
use File::Basename;
use File::Spec::Memoized;
use Memoize;

memoize('create_xslate');
sub create_xslate{ Text::Xslate->new(@_) } # It is memoized!

sub import {
    my($class, $option) = @_;
    my $pkg = caller(0);

    undef $option unless(defined($option) && ref($option) eq 'HASH');

    no strict 'refs';
    *{"$pkg\::create_template"} = sub {
        my($self, $file) = @_;
        return $class->new($file, $self, $option);
    };
}

sub new {
    my($class, $file, $page, $option) = @_;

    my $config = $page->create_config();

    my $_option = {
        filename    => $file,
        path        => [dirname($file), '.', '/'],
        input_layer => ':encoding(euc-jp)',# Sledge's default encoding is euc-jp (not utf-8)
        suffix      => '.html',
        type        => 'html',
        cache       => 1
    };

    if(defined($option)){
        foreach my $key (keys(%$option)){
            $_option->{$key} = $option->{$key};
        }
    }

    my $self = {
        _options => $_option,
        _params  => {
            config  => $config,
            r       => $page->r,
            session => $page->session,
        }
    };

    bless($self, $class);
}

sub add_associate       { Sledge::Exception::UnimplementedMethod->throw }
sub associate_namespace { Sledge::Exception::UnimplementedMethod->throw }

sub output {
    my $self = shift;
    my $config = $self->{_options};
    my $input  = delete $config->{filename};
    my $cache_dir = $self->{'_params'}->{'config'}->can('cache_dir') ?
        $self->{'_params'}->{'config'}->cache_dir : undef;

    # Template file check
    unless (ref($input) || -e $input) {
        Sledge::Exception::TemplateNotFound->throw(
            "No template file detected: $input",
        );
    }

    # Create object
    my $template = create_xslate($config);

    # Render
    return ((ref $input eq 'SCALAR') ?
            $template->render_string($$input, $self->{_params}):
            $template->render($input, $self->{_params})
	) or Sledge::Exception::TemplateParseError->throw($template->error);
}

1;
__END__

=head1 NAME

Sledge::Template::Xslate - Text::Xslate template system for Sledge

=head1 VERSION

This document describes Sledge::Template::Xslate version 0.09

=head1 SYNOPSIS

    package MyApp::Pages;
    use strict;
    use Sledge::Pages::Compat;
    use Sledge::Template::Xslate ({
      syntax => 'TTerse',
      module => ['Text::Xslate::Bridge::TT2Like'],
      input_layer => ':utf8',# Please set input_layer if you want to use utf-8.
      # You can set more option.
    });

    # ...

=head1 DESCRIPTION

Sledge::Template::Xslate is Text::Xslate template system for Sledge.

=head1 AUTHOR

Kenta Sato  C<< <kenta.sato.1990@gmail.com> >>

=head1 SEE ALSO

Sledge( Repository - http://sourceforge.jp/projects/sledge/ )
Sledge::Template
L<Text::Xslate>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__END__

