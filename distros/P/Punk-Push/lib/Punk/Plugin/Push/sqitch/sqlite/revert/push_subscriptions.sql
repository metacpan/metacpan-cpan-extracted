-- Revert punk_push:push_subscriptions from sqlite

BEGIN;

DROP TABLE push_subscriptions;

COMMIT;
