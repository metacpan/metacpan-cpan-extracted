-- Verify punk_push:push_subscriptions on sqlite

SELECT id, user_id, endpoint, p256dh, auth, user_agent,
       created_at, last_seen_at, last_status
  FROM push_subscriptions WHERE 0;
