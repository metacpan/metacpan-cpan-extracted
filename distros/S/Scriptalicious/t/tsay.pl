
use Scriptalicious;

tsay hello => { name => "Bernie" };

__END__

__hello__
Hello, [% name %]
[% INCLUDE yomomma -%]
__yomomma__
[% PROGNAME %]: Yo momma's so fat your family portrait has stretchmarks.
