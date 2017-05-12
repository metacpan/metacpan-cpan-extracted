# Hint for AIX. It seems to want the 'rtl' option to allow the use
# of .so libraries.
$self->{dynamic_lib} = {OTHERLDFLAGS => '-brtl -ltdusr -lcliv2 -lnsl'};
