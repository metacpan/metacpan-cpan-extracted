package Module::Build::My;

use strict;
use warnings;

use base 'Module::Build';

use File::Spec;

# Replace *.pl files with ones without suffix

sub process_script_files {
    my $self = shift;

    local *copy_if_modified = sub {
        my $self = shift;
        my %args = (@_ > 3 ? ( @_ ) : ( from => shift, to_dir => shift, flatten => shift ) );
        # Only for script/*.pl files
        if ($args{from} =~ /\bscript\/.*\.pl$/ and $args{to_dir}) {
            my (undef, undef, $file) = File::Spec->splitpath($args{from});
            $file =~ s/\.pl$//;
            $args{to} = File::Spec->catfile($args{to_dir}, $file);
            delete $args{to_dir};
            return $self->SUPER::copy_if_modified(%args);
        };
        return $self->SUPER::copy_if_modified(%args);
    };

    $self->SUPER::process_script_files;
};

1;
