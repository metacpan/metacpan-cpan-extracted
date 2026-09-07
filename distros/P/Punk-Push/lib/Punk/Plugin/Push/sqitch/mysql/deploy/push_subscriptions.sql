-- Deploy punk_push:push_subscriptions to mysql

BEGIN;

-- endpoint is indexed with a prefix length: MySQL cannot index a full TEXT
-- column, and a push endpoint is long. 255 bytes is well past the point where
-- two endpoints from one push service diverge.
CREATE TABLE push_subscriptions (
    id           BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id      BIGINT NOT NULL,
    endpoint     TEXT   NOT NULL,
    p256dh       TEXT   NOT NULL,
    auth         TEXT   NOT NULL,
    user_agent   TEXT,
    created_at   BIGINT NOT NULL,
    last_seen_at BIGINT,
    last_status  INTEGER,
    UNIQUE KEY push_subscriptions_endpoint (endpoint(255)),
    KEY push_subscriptions_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

COMMIT;
