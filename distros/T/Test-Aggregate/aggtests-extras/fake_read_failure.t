# Simulate a test script that exists but fails to read:
# Set $! accordingly and don't run any tests.

{ open(my $fh, '<', 'a-file-that-almost-certainly-does.not.exist'); }
