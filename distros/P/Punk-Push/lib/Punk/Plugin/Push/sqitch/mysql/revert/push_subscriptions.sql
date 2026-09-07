-- Revert punk_push:push_subscriptions from mysql

BEGIN;

DROP TABLE push_subscriptions;

COMMIT;
