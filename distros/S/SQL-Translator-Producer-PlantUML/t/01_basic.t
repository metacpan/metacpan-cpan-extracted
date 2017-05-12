use strict;
use warnings;
use Test::More;
use SQL::Translator;

my $t = SQL::Translator->new(
    from => 'MySQL',
    to   => 'PlantUML',
);

my $got = $t->translate(\<<'___');
CREATE TABLE user (
    id   INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(191)     NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8mb4;

CREATE TABLE item (
    id   INTEGER UNSIGNED NOT NULL,
    name VARCHAR(191)     NOT NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8mb4;

CREATE TABLE user_item (
    user_id INTEGER UNSIGNED NOT NULL,
    item_id INTEGER UNSIGNED NOT NULL,
    amount  INTEGER UNSIGNED NOT NULL,
    PRIMARY KEY (user_id, item_id),
    FOREIGN KEY (user_id) REFERENCES user (id),
    FOREIGN KEY (item_id) REFERENCES item (id)
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8mb4;

CREATE TABLE user_item_history (
    id         INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id    INTEGER UNSIGNED NOT NULL,
    item_id    INTEGER UNSIGNED NOT NULL,
    how_get    INTEGER UNSIGNED NOT NULL,
    how_out    INTEGER UNSIGNED NOT NULL,
    amount     INTEGER UNSIGNED NOT NULL,
    created_at DATETIME         NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (user_id, item_id) REFERENCES user_item (user_id, item_id)
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8mb4;
___

$got =~ s/^\s*\n//mg;
is $got, <<'___';
@startuml
object user {
    - id
    name
}
object item {
    - id
    name
}
object user_item {
    - user_id (FK)
    - item_id (FK)
    amount
}
object user_item_history {
    - id
    user_id (FK)
    item_id (FK)
    how_get
    how_out
    amount
    created_at
}
user --o user_item
item --o user_item
user_item --o user_item_history
@enduml
___

done_testing;
