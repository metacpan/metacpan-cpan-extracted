-- Revert punk_push:push_subscriptions from pg

BEGIN;

DROP TABLE push_subscriptions;

COMMIT;
