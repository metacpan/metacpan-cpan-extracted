SET CLIENT_MIN_MESSAGES = ERROR;

ALTER TABLE "User"
  RENAME activation_key TO confirmation_key;

ALTER TABLE ONLY "User"
  ADD CONSTRAINT "User_confirmation_key_key" UNIQUE (confirmation_key);

ALTER TABLE ONLY "User"
  DROP CONSTRAINT "User_activation_key_key";

