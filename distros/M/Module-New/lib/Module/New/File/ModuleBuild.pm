package Module::New::File::ModuleBuild;

use strict;
use warnings;
use Module::New::File;

file 'Build.PL' => content { return <<'EOT';
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => '<%= $c->module %>',
    license           => '<%= $c->config('license') || 'perl' %>',
    dist_author       => '<%= $c->config('author') %> <<%= $c->config('email') %>>',
    dist_version_from => '<%= $c->mainfile %>',
    requires => {
    },
    build_requires => {
        'Test::More'          => '0.88', # for done_testing
        'Test::UseAllModules' => '0.10',
    },
    resources => {
        repository => '<%= $c->repository %>',
    },
);

$builder->create_build_script;
EOT
};

1;

__END__

=head1 NAME

Module::New::File::ModuleBuild

=head1 DESCRIPTION

a template for C<Build.PL> (with L<Module::Build>).

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
