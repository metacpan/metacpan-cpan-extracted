use strict;
use warnings;

use Setup::Project::CLI qw(usage);
use Setup::Project::Functions;

my $cli  = Setup::Project::CLI->new;
$cli->version('0.01');

my %vars = equal_style($cli->argv);

my $maker = $cli->maker(tmpl_dir => scriptdir('<% $flavor_name %>'));

$maker->file_vars(
    %vars,
    flavor_info => flavor_info(),
);
$maker->filename_vars();

$maker->safely_run(sub {
    $maker->render_all_files;
});
