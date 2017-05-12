use FindBin;
use Test::Requires {
    'Test::NoTabs' => 0,
};

all_perl_files_ok("$FindBin::Bin/../lib");

__END__

=pod

=head1 NAME

no_tabs.t - testing presence of tabs

=head1 NOTE

C<< all_perl_files_ok() >> is bad because C<< inc/ModuleInstall/* >> will die.

=cut
