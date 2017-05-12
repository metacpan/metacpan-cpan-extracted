use strict;
use Mvalve;

# If you haven't already done so, you need to create these q4m
# enabled tables in your mysql database.
#
# CREATE TABLE q_emerg (
#    destination VARCHAR(40) NOT NULL,
#    message     BLOB NOT NULL
# ) ENGINE=QUEUE DEFAULT CHARSET=UTF-8
#
# CREATE TABLE q_timed (
#    destination VARCHAR(40) NOT NULL,
#    ready       BIGINT NOT NULL,
#    message     BLOB NOT NULL
# ) ENGINE=QUEUE DEFAULT CHARSET=UTF-8
#
# CREATE TABLE q_incoming (
#    destination VARCHAR(40) NOT NULL,
#    message     BLOB NOT NULL
# ) ENGINE=QUEUE DEFAULT CHARSET=UTF-8
#
