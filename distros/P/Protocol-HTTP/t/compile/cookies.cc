#include "../lib/test.h"

#define TEST(name) TEST_CASE("compile-cookies: " name, "[compile-cookies]")

TEST("request single cookie") {
    RequestSP req;
    SECTION("via request") {
        req = new Request();
        req->cookies.add("hello", "world");
    }
    SECTION("via builder") {
        req = Request::Builder().cookie("hello", "world").build();
    }

    CHECK(req->to_string() ==
        "GET / HTTP/1.1\r\n"
        "Cookie: hello=world\r\n"
        "\r\n"
    );
}

TEST("request multiple cookies") {
    auto req = Request::Builder().cookie("c1", "v1").cookie("c2", "v2").cookie("c3", "v3").build();
    CHECK(req->to_string() ==
        "GET / HTTP/1.1\r\n"
        "Cookie: c1=v1; c2=v2; c3=v3\r\n"
        "\r\n"
    );
}

TEST("response cookie in vacuum") {
    panda::time::tzset("Europe/Moscow");
    Response::Cookie coo("v");

    SECTION("nothing") {
        CHECK(coo.to_string("k") == "k=v");
    }
    SECTION("no value") {
        CHECK(coo.value("").to_string("k") == "k=");
    }
    SECTION("domain") {
        SECTION("specified") {
            CHECK(coo.domain("crazypanda.ru").to_string("k") == "k=v; Domain=crazypanda.ru");
        }
        SECTION("specified with req") {
            auto req = Request::Builder().header("Host", "wpc.ru").build();
            CHECK(coo.domain("override.crazypanda.ru").to_string("k", req) == "k=v; Domain=override.crazypanda.ru");
        }
        SECTION("not specified with req") {
            auto req = Request::Builder().header("Host", "wpc.ru").build();
            CHECK(coo.to_string("k", req) == "k=v; Domain=wpc.ru");
        }
    }
    SECTION("path") {
        CHECK(coo.path("/erase/all").to_string("k") == "k=v; Path=/erase/all");
    }
    SECTION("max-age") {
        CHECK(coo.max_age(999).to_string("k") == "k=v; Max-Age=999");
    }
    SECTION("expires") {
        CHECK(coo.expires(Date("2019-11-28 21:43:59")).to_string("k") == "k=v; Expires=Thu, 28 Nov 2019 18:43:59 GMT");
    }
    SECTION("secure") {
        CHECK(coo.secure(true).to_string("k") == "k=v; Secure");
    }
    SECTION("http only") {
        CHECK(coo.http_only(true).to_string("k") == "k=v; HttpOnly");
    }
    SECTION("same site") {
        SECTION("Strict") {
            CHECK(coo.same_site(Response::Cookie::SameSite::Strict).to_string("k") == "k=v; SameSite");
        }
        SECTION("Lax") {
            CHECK(coo.same_site(Response::Cookie::SameSite::Lax).to_string("k") == "k=v; SameSite=Lax");
        }
        SECTION("None") {
            CHECK(coo.same_site(Response::Cookie::SameSite::None).to_string("k") == "k=v; SameSite=None");
        }
    }
    SECTION("all together") {
        CHECK(
            coo.domain(".crazypanda.ru").path("/epta").max_age(888).secure(true).http_only(true).to_string("k") ==
            "k=v; Domain=.crazypanda.ru; Path=/epta; Max-Age=888; Secure; HttpOnly"
        );
    }
}

TEST("response single cookie") {
    auto req = Request::Builder().header("host", "epta.ru").build();
    auto res = Response::Builder().cookie("session", Response::Cookie("abcdef").max_age(1000).path("/").http_only(true)).build();
    CHECK(res->to_string(req) ==
        "HTTP/1.1 200 OK\r\n"
        "Content-Length: 0\r\n"
        "Set-Cookie: session=abcdef; Domain=epta.ru; Path=/; Max-Age=1000; HttpOnly\r\n"
        "\r\n"
    );
}

TEST("response multiple cookies") {
    auto req = Request::Builder().header("host", "epta.ru").build();
    auto res = Response::Builder().cookie("session", Response::Cookie("abcdef")).cookie("killmenow", Response::Cookie("yeah")).build();
    CHECK(res->to_string(req) ==
        "HTTP/1.1 200 OK\r\n"
        "Content-Length: 0\r\n"
        "Set-Cookie: session=abcdef; Domain=epta.ru\r\n"
        "Set-Cookie: killmenow=yeah; Domain=epta.ru\r\n"
        "\r\n"
    );
}
