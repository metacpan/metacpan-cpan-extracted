package Spoon::Template;
use Spoon::Base -Base;
use Template;

const class_id => 'template';
const template_path => [ './template' ];
field path => [];
stub 'render';
field config => -init => '$self->hub->config';
field cgi => -init => '$self->hub->cgi';

sub init {
    $self->add_path(@{$self->template_path});
}

sub all {
    return ( 
        $self->config->all,
        $self->is_in_cgi ? ($self->cgi->all) : (),
        hub => $self->hub,
    );
}

sub add_path {
    for (reverse @_) {
        $self->remove_path($_);
        unshift @{$self->path}, $_;
    }
}

sub append_path {
    for (@_) {
        $self->remove_path($_);
        push @{$self->path}, $_;
    }
}

sub remove_path {
    my $path = shift;
    $self->path([grep {$_ ne $path} @{$self->path}]);
}

sub process {
    my $template = shift;
    my @templates = (ref $template eq 'ARRAY')
      ? @$template 
      : $template;
    return join '', map {
        $self->render($_, $self->all, @_)
    } @templates;
}

__END__

=head1 NAME 

Spoon::Template - Spoon Template Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
