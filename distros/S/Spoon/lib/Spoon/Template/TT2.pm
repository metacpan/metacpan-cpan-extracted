package Spoon::Template::TT2;
use Spoon::Template -Base;

field template_object =>
      -init => '$self->create_template_object';

sub compile_dir {
    my $dir = $self->plugin_directory . '/ttc';
    mkdir $dir unless -d $dir;
    return $dir;
}
        
sub create_template_object {
    require Template;
    # XXX Make template caching a configurable option
    Template->new({
        INCLUDE_PATH => $self->path,
        TOLERANT => 0,
        COMPILE_DIR => $self->compile_dir,
        COMPILE_EXT => '.ttc',
    });
}

sub render {
    my $template = shift;

    my $output;
    my $t = $self->template_object;
    eval {
        $t->process($template, {@_}, \$output) or die $t->error;
    };
    die "Template Toolkit error:\n$@" if $@;
    return $output;
}

__DATA__

=head1 NAME

Spoon::Template::TT2 - Spoon Template Toolkit Base Class

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
