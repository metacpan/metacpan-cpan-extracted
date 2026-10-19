SECURITY POLICY

If you discover a security vulnerability in this distribution,
please report it privately to:

    info@petamem.com

Please do not open a public issue for security vulnerabilities.
We will acknowledge receipt within 48 hours and aim to provide
a fix within 7 days for confirmed issues.

MIDI files and banks are read as data; neither is executed.

peta-synth serve listens on 127.0.0.1 unless --host says otherwise,
and asks nobody who they are: whoever can reach it can play the MIDI
files of its directory, change the instruments and save the bank.
