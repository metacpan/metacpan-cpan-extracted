# productshotai-site-kit

Public URL helpers and metadata constants for [ProductShot AI](https://productshotai.app), an AI product photography generator for ecommerce sellers.

## What is ProductShot AI?

ProductShot AI helps ecommerce sellers generate product photos, white backgrounds, marketplace main images, and lifestyle product scenes from product images.

## Features

- Build URLs for workbench, pricing, blog, support, legal, and localized pages
- Expose public metadata for ProductShot AI package integrations
- Preserve ProductShot's public English URL rule: English is prefixless, Simplified Chinese uses `/zh/`
- Multi-ecosystem: available on npm, PyPI, crates.io, Go, RubyGems, pub.dev, Hex.pm, Clojars, and Docker Hub
- New package ecosystem helpers prepared for JSR, Maven Central/javadoc.io, NuGet, CocoaPods, LuaRocks, CPAN/MetaCPAN, Hackage, Chocolatey, GitHub Packages, and GitLab Package Registry

## Installation

```bash
npm install productshotai-site-kit
pip install productshotai-site-kit
cargo add productshotai-site-kit
go get github.com/bbwdadfg/productshotai-site-kit
gem install productshotai-site-kit
dart pub add productshotai_site_kit
mix hex.install productshotai_site_kit
```

Additional ecosystem manifests and helper sources are included for trial publishing on newer channels:

- JSR: `jsr.json`, `mod.ts`
- CPAN/MetaCPAN: `Makefile.PL`, `lib/ProductShotAI/SiteKit.pm`
- Maven Central/javadoc.io: `src/main/java/app/productshotai/sitekit/SiteKit.java`
- NuGet: `nuget/ProductShotAI.SiteKit/ProductShotAI.SiteKit.csproj`
- CocoaPods: `ProductShotAISiteKit.podspec`
- LuaRocks: `productshotai-site-kit-0.1.0-1.rockspec`
- Hackage: `productshotai-site-kit.cabal`
- Chocolatey: `chocolatey/productshotai-site-kit.nuspec`
- Open VSX: `open-vsx/`
- WordPress Plugin Directory: `wordpress/productshotai-site-kit/`

## Usage

```js
// JavaScript / Node.js
const { metadata, workbenchUrl, pricingUrl, localizedUrl } = require('productshotai-site-kit');

console.log(metadata().name);
// => "ProductShot AI"

console.log(pricingUrl());
// => "https://productshotai.app/#pricing"

console.log(workbenchUrl());
// => "https://productshotai.app/#workbench"

console.log(localizedUrl('zh', '/blog'));
// => "https://productshotai.app/zh/blog/"
```

## Links

- **Website**: https://productshotai.app
- **Workbench**: https://productshotai.app/#workbench
- **Pricing**: https://productshotai.app/#pricing
- **Blog**: https://productshotai.app/blog/
- **Contact**: https://productshotai.app/contact/
- **GitHub**: https://github.com/bbwdadfg/productshotai-site-kit

## License

MIT
