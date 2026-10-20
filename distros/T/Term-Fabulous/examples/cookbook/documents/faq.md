# Frequently asked questions

## Does snapback encrypt the backups?

No. Put the backup disk on an encrypted file system, or encrypt the backup
in a [hook](snapback.md#Hooks).

## Can I back up to another computer?

Not directly: snapback writes to a directory. Mount the other computer's
disk over the network and give snapback the mounted directory, or copy each
new backup from a hook.

## Why is the second backup so small?

Files that did not change are hard links to the backup before, so only the
changes take space. See [your first backup](snapback.md#Your%20first%20backup).

## How do I get back to the manual?

Follow [this link](snapback.md), or press Backspace to go back.
