# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 99;

BEGIN
{
	use_ok( 'Net::API::Telegram' );
	use_ok( 'Net::API::Telegram::Animation' );
	use_ok( 'Net::API::Telegram::Audio' );
	use_ok( 'Net::API::Telegram::CallbackGame' );
	use_ok( 'Net::API::Telegram::CallbackQuery' );
	use_ok( 'Net::API::Telegram::Chat' );
	use_ok( 'Net::API::Telegram::ChatMember' );
	use_ok( 'Net::API::Telegram::ChatPermissions' );
	use_ok( 'Net::API::Telegram::ChatPhoto' );
	use_ok( 'Net::API::Telegram::ChosenInlineResult' );
	use_ok( 'Net::API::Telegram::Contact' );
	use_ok( 'Net::API::Telegram::Document' );
	use_ok( 'Net::API::Telegram::EncryptedCredentials' );
	use_ok( 'Net::API::Telegram::EncryptedPassportElement' );
	use_ok( 'Net::API::Telegram::File' );
	use_ok( 'Net::API::Telegram::ForceReply' );
	use_ok( 'Net::API::Telegram::Game' );
	use_ok( 'Net::API::Telegram::GameHighScore' );
	use_ok( 'Net::API::Telegram::Generic' );
	use_ok( 'Net::API::Telegram::InlineKeyboardButton' );
	use_ok( 'Net::API::Telegram::InlineKeyboardMarkup' );
	use_ok( 'Net::API::Telegram::InlineQuery' );
	use_ok( 'Net::API::Telegram::InlineQueryResult' );
	use_ok( 'Net::API::Telegram::InlineQueryResultArticle' );
	use_ok( 'Net::API::Telegram::InlineQueryResultAudio' );
	use_ok( 'Net::API::Telegram::InlineQueryResultCachedAudio' );
	use_ok( 'Net::API::Telegram::InlineQueryResultCachedDocument' );
	use_ok( 'Net::API::Telegram::InlineQueryResultCachedGif' );
	use_ok( 'Net::API::Telegram::InlineQueryResultCachedMpeg4Gif' );
	use_ok( 'Net::API::Telegram::InlineQueryResultCachedPhoto' );
	use_ok( 'Net::API::Telegram::InlineQueryResultCachedSticker' );
	use_ok( 'Net::API::Telegram::InlineQueryResultCachedVideo' );
	use_ok( 'Net::API::Telegram::InlineQueryResultCachedVoice' );
	use_ok( 'Net::API::Telegram::InlineQueryResultContact' );
	use_ok( 'Net::API::Telegram::InlineQueryResultDocument' );
	use_ok( 'Net::API::Telegram::InlineQueryResultGame' );
	use_ok( 'Net::API::Telegram::InlineQueryResultGif' );
	use_ok( 'Net::API::Telegram::InlineQueryResultLocation' );
	use_ok( 'Net::API::Telegram::InlineQueryResultMpeg4Gif' );
	use_ok( 'Net::API::Telegram::InlineQueryResultPhoto' );
	use_ok( 'Net::API::Telegram::InlineQueryResultVenue' );
	use_ok( 'Net::API::Telegram::InlineQueryResultVideo' );
	use_ok( 'Net::API::Telegram::InlineQueryResultVoice' );
	use_ok( 'Net::API::Telegram::InputContactMessageContent' );
	use_ok( 'Net::API::Telegram::InputFile' );
	use_ok( 'Net::API::Telegram::InputLocationMessageContent' );
	use_ok( 'Net::API::Telegram::InputMedia' );
	use_ok( 'Net::API::Telegram::InputMediaAnimation' );
	use_ok( 'Net::API::Telegram::InputMediaAudio' );
	use_ok( 'Net::API::Telegram::InputMediaDocument' );
	use_ok( 'Net::API::Telegram::InputMediaPhoto' );
	use_ok( 'Net::API::Telegram::InputMediaVideo' );
	use_ok( 'Net::API::Telegram::InputMessageContent' );
	use_ok( 'Net::API::Telegram::InputTextMessageContent' );
	use_ok( 'Net::API::Telegram::InputVenueMessageContent' );
	use_ok( 'Net::API::Telegram::Invoice' );
	use_ok( 'Net::API::Telegram::KeyboardButton' );
	use_ok( 'Net::API::Telegram::LabeledPrice' );
	use_ok( 'Net::API::Telegram::Location' );
	use_ok( 'Net::API::Telegram::LoginUrl' );
	use_ok( 'Net::API::Telegram::MaskPosition' );
	use_ok( 'Net::API::Telegram::Message' );
	use_ok( 'Net::API::Telegram::MessageEntity' );
	use_ok( 'Net::API::Telegram::Number' );
	use_ok( 'Net::API::Telegram::OrderInfo' );
	use_ok( 'Net::API::Telegram::PassportData' );
	use_ok( 'Net::API::Telegram::PassportElementError' );
	use_ok( 'Net::API::Telegram::PassportElementErrorDataField' );
	use_ok( 'Net::API::Telegram::PassportElementErrorFile' );
	use_ok( 'Net::API::Telegram::PassportElementErrorFiles' );
	use_ok( 'Net::API::Telegram::PassportElementErrorFrontSide' );
	use_ok( 'Net::API::Telegram::PassportElementErrorReverseSide' );
	use_ok( 'Net::API::Telegram::PassportElementErrorSelfie' );
	use_ok( 'Net::API::Telegram::PassportElementErrorTranslationFile' );
	use_ok( 'Net::API::Telegram::PassportElementErrorTranslationFiles' );
	use_ok( 'Net::API::Telegram::PassportElementErrorUnspecified' );
	use_ok( 'Net::API::Telegram::PassportFile' );
	use_ok( 'Net::API::Telegram::PhotoSize' );
	use_ok( 'Net::API::Telegram::Poll' );
	use_ok( 'Net::API::Telegram::PollOption' );
	use_ok( 'Net::API::Telegram::PreCheckoutQuery' );
	use_ok( 'Net::API::Telegram::ReplyKeyboardMarkup' );
	use_ok( 'Net::API::Telegram::ReplyKeyboardRemove' );
	use_ok( 'Net::API::Telegram::Response' );
	use_ok( 'Net::API::Telegram::ResponseParameters' );
	use_ok( 'Net::API::Telegram::ShippingAddress' );
	use_ok( 'Net::API::Telegram::ShippingOption' );
	use_ok( 'Net::API::Telegram::ShippingQuery' );
	use_ok( 'Net::API::Telegram::Sticker' );
	use_ok( 'Net::API::Telegram::StickerSet' );
	use_ok( 'Net::API::Telegram::SuccessfulPayment' );
	use_ok( 'Net::API::Telegram::Update' );
	use_ok( 'Net::API::Telegram::User' );
	use_ok( 'Net::API::Telegram::UserProfilePhotos' );
	use_ok( 'Net::API::Telegram::Venue' );
	use_ok( 'Net::API::Telegram::Video' );
	use_ok( 'Net::API::Telegram::VideoNote' );
	use_ok( 'Net::API::Telegram::Voice' );
	use_ok( 'Net::API::Telegram::WebhookInfo' );
}

# my $object = Net::API::Telegram->new;
# isa_ok ($object, 'Net::API::Telegram');


