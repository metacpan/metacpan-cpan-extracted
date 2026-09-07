-- Deploy punk_push:push_subscriptions to pg

BEGIN;

-- user_id is a column, not a foreign key to any users table: it is not this
-- project's business what the application calls its users, and a plugin's
-- Sqitch project cannot depend on the application's own, which deploys last.
--
-- endpoint is UNIQUE and that is load-bearing. A browser re-subscribing
-- produces the same endpoint; without the constraint every re-subscribe adds a
-- row and one send fans out across the duplicates, so a user is notified once
-- for every time they ever visited the site.
CREATE TABLE push_subscriptions (
    id           bigserial PRIMARY KEY,
    user_id      bigint NOT NULL,
    endpoint     text   NOT NULL,
    p256dh       text   NOT NULL,
    auth         text   NOT NULL,
    user_agent   text,
    created_at   bigint NOT NULL,
    last_seen_at bigint,
    last_status  integer
);

CREATE UNIQUE INDEX push_subscriptions_endpoint ON push_subscriptions (endpoint);
CREATE INDEX push_subscriptions_user ON push_subscriptions (user_id);

COMMIT;
