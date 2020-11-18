use Test::More;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling" if $@;
add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
INI
Win32
filename
ini
mrdvt92
GitHub
320x240
ICamera2
IP
JPEG
MERCHANTABILITY
NONINFRINGEMENT
Sercomm
cpan
getSnapshot
hostname
imageSettingsQuality
imageSettingsSize
mrdvt
sublicense
ICamera
