package SVN::Hook::Script;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw(hook enabled path));

use Path::Class;

# returns an array of SVN::Hook::Script objects
sub load_from_dir {
    my $class = shift;
    my $dir   = shift;
    my $hook  = shift;

    return map {
        SVN::Hook::Script->new(
            {   hook    => $hook,
                path    => Path::Class::File->new($_),
                enabled => (!m/-$/ && -x $_ )
            })
        } grep { -f $_ } glob( "$dir/*" );
}

1;
