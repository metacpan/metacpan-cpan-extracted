use 5.014;

use Running::Commentary;
use Test::Effects;
use Carp;

plan tests => 5;

effects_ok { run -critical, '# critical block' => sub { die } }
           {
                stdout => qr/critical block/,
                die    => qr/critical block/,
                WITHOUT => 'Term::ANSIColor',
           } => 'Critical self-message';

effects_ok { run -critical, '# critical block' => sub { die 'exception text' } }
           {
                stdout => qr/exception text/,
                die    => qr/exception text/,
                WITHOUT => 'Term::ANSIColor',
           } => 'Critical exception text';

effects_ok { run '# Noncritical block' => sub { say "Should not throw exception" }, -critical }
           {
                stdout => qr/Should not throw exception/,
                WITHOUT => 'Term::ANSIColor',
           } => 'Non-critical';

effects_ok { run -critical, -nomessage, '# critical cmd' => 'dhsjhdsdhksahdsa' }
           {
                stdout => q{},
                die    => qr/Failed system call/,
                WITHOUT => 'Term::ANSIColor',
           } => 'Critical nomessage';

effects_ok { run -critical, -nomessage, '# Non-critical cmd' => 'echo "Should not throw exception"' }
           {
                stdout => qr/Should not throw exception/,
                WITHOUT => 'Term::ANSIColor',
           } => 'Critical nomessage non-fail';
