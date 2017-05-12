## no critic (RequireUseStrict)
package Tapper::Reports::DPath::Mason;
our $AUTHORITY = 'cpan:TAPPER';
# ABSTRACT: Mix DPath into Mason templates
$Tapper::Reports::DPath::Mason::VERSION = '5.0.2';
use 5.010;
        use Moose;

        use HTML::Mason;
        use Cwd 'cwd';
        use Data::Dumper;
        use File::ShareDir 'module_dir';

        has debug           => ( is => 'rw');
        has puresqlabstract => ( is => 'rw', default => 0);

        sub render {
                my ($self, %args) = @_;

                my $file     = $args{file};
                my $template = $args{template};

                return $self->render_file     ($file)     if $file;
                return $self->render_template ($template) if $template;
        }

        sub render_template {
                my ($self, $template) = @_;

                my $outbuf;
                my $comp_root = module_dir('Tapper::Reports::DPath::Mason');

                local $Tapper::Reports::DPath::puresqlabstract = $self->puresqlabstract;
                my $interp = new HTML::Mason::Interp
                    (
                     use_object_files => 1,
                     comp_root        => $comp_root,
                     out_method       => \$outbuf,
                     preloads         => [ '/mason_include.pl' ],
                    );
                my $anon_comp = eval {
                        $interp->make_component
                            (
                             comp_source => $template,
                             name        => '/virtual/tapper_reports_dpath_mason',
                            );
                };
                if ($@) {
                        my $msg = "Tapper::Reports::DPath::Mason::render_template::make_component: ".$@;
                        print STDERR $msg;
                        return $msg if $self->debug;
                        return '';
                }
                eval {
                        $interp->exec($anon_comp);
                };
                if ($@) {
                        my $msg = "Tapper::Reports::DPath::Mason::render_template::exec(anon_comp): ".$@;
                        print STDERR $msg;
                        return $msg if $self->debug;
                        return '';
                }
                return $outbuf;
        }

        sub render_file {
                my ($self, $file) = @_;

                # must be absolute to mason, although meant relative in real world
                $file = "/$file" unless $file =~ m(^/);

                my $outbuf;
                my $interp;
                eval {
                        $interp = new HTML::Mason::Interp(
                                                          use_object_files => 1,
                                                          comp_root => cwd(),
                                                          out_method       => \$outbuf,
                                                         );
                };
                if ($@) {
                        my $msg = "Tapper::Reports::DPath::Mason::render_file::new_Interp: ".$@;
                        print STDERR $msg;
                        return $msg if $self->debug;
                        return '';
                }
                eval { $interp->exec($file) };
                if ($@) {
                        my $msg = "Tapper::Reports::DPath::Mason::render_file::exec(file): ".$@;
                        print STDERR $msg;
                        return $msg if $self->debug;
                        return '';
                }
                return $outbuf;
        }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::DPath::Mason - Mix DPath into Mason templates

=head1 SYNOPSIS

    use Tapper::Reports::DPath::Mason 'render';
    $result = render file => $filename;
    $result = render template => $string;

=head1 METHODS

=head2 render

Render file or template.

=head2 render_file

Render file.

=head2 render_template

Render template.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
