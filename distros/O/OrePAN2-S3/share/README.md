<a id="readme" class="anchor" aria-label="Permalink: README" href="#readme"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">README</h1>
<a id="table-of-contents" class="anchor" aria-label="Permalink: Table of Contents" href="#table-of-contents"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">Table of Contents</h1>
<ul>
<li><a href="#readme">README</a></li>
<li>
<a href="#prerequisites">Prerequisites</a>
<ul>
<li><a href="#install-this-distribution-from-cpan">Install this Distribution from CPAN</a></li>
<li><a href="#orepan2-s3json"><code>.orepan2-s3.json</code></a></li>
</ul>
</li>
<li>
<a href="#adding-a-new-distribution-to-your-darkpan">Adding a New Distribution to Your DarkPAN</a>
<ul>
<li><a href="#the-default-index">The Default Index</a></li>
<li><a href="#distribution-documentation">Distribution Documentation</a></li>
</ul>
</li>
<li>
<a href="#using-a-website-enabled-s3-bucket">Using a Website Enabled S3 Bucket</a>
<ul>
<li><a href="#warning!">WARNING!</a></li>
</ul>
</li>
</ul>
<p>This is the README file for the <code>OrePAN2::S3</code> distribution. The intent
of this project is to create a so-called DarkPAN mirror that serves
CPAN distributions from an S3 bucket behind a CloudFront distribution.
However, this project can also support a website enabled S3 bucket
without using CloudFront.</p>
<a id="prerequisites" class="anchor" aria-label="Permalink: Prerequisites" href="#prerequisites"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">Prerequisites</h1>
<ul>
<li>An AWS account</li>
<li>An S3 bucket</li>
<li>A CloudFront distribution</li>
<li>...and several Perl modules (see <a href="requires">requires</a>)</li>
</ul>
<p>You should set up your S3 bucket and CloudFront distribution before
proceeding. You can use this
<a href="https://github.com/rlauer6/s3-static-site">project</a> to set up your
infrastructure. That project will explain how to
create and secure your own private static website hosted on S3.  A
script is included in that project to help you create all of the AWS
artifacts required.</p>
<a id="install-this-distribution-from-cpan" class="anchor" aria-label="Permalink: Install this Distribution from CPAN" href="#install-this-distribution-from-cpan"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Install this Distribution from CPAN</h2>
<pre><code>cpanm -v OrePAN2::S3
</code></pre>
<p>This will install two <code>bash</code> scripts:</p>
<table>
<thead>
<tr>
<th>Script Name</th>
<th>Description</th>
</tr>
</thead>
<tbody>
<tr>
<td><code>orepan2-s3</code></td>
<td>Used to add new distributions to your DarkPAN</td>
</tr>
<tr>
<td><code>orepan2-s3-index</code></td>
<td>Called by <code>orepan2-s3</code> to create an <code>index.html</code>
</td>
</tr>
</tbody>
</table>
<div class="markdown-heading"><h2 class="heading-element"><code>.orepan2-s3.json</code></h2><a id="orepan2-s3json" class="anchor" aria-label="Permalink: .orepan2-s3.json" href="#orepan2-s3json"><span aria-hidden="true" class="octicon octicon-link"></span></a></div>
<p>Set up a configuration file that will be used by the scripts. If you
run <code>orepan2-s3</code> the first time and there is no configuration, a
default configuration will be installed in your home directory that
looks something like this:</p>
<pre><code>{
 "default": {
    "AWS": {
        "profile" : "prod",
        "region" : "us-east-1",
        "bucket" : "my-bucket",
        "prefix" : "orepan2"
    },
    "CloudFront" : {
        "DistributionId" : "**************"
    }
 }
}
</code></pre>
<p>Note this is the minimum configuration. See <code>perldoc OrePAN::S3</code> for
more configuration file options.</p>
<p>If you are not using a CloudFront distribution (see below), remove or set the
DistributionId to "".</p>
<p><a href="#table-of-contents">Back to Table of Contents</a></p>
<a id="adding-a-new-distribution-to-your-darkpan" class="anchor" aria-label="Permalink: Adding a New Distribution to Your DarkPAN" href="#adding-a-new-distribution-to-your-darkpan"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">Adding a New Distribution to Your DarkPAN</h1>
<pre><code>orepan2-s3 add {tarball}
</code></pre>
<p>Example:</p>
<pre><code>orepan2-s3 add OrePAN2-S3-0.01.tar.gz
</code></pre>
<p>When you add a file to the DarkPAN repository the script will:</p>
<ul>
<li>Upload the file to your S3 bucket</li>
<li>Update the package index</li>
<li>Create a default <code>/index.html</code> page that shows all of your
distributions</li>
<li>Invalidate the CloudFront cache if you are using CloudFront</li>
</ul>
<p>By default, the script invalidates the CloudFront cache if it finds a
<code>DistributionId</code> in your configuration. You'll need to invalidate the
cache in order to see your updates to the <code>index.html</code> and the DarkPAN
index.  If you don't need to do that because your TTL on your
CloudFront distribution is fairly low, use the <code>-x</code> option to prevent
the script from invalidating the cache.</p>
<blockquote>
<p>Note: In order to invalidate the CloudFront cache your AWS account
credentials must have permissions for CloudFront operations.</p>
</blockquote>
<p>Keep in mind that AWS gives you 1000 invalidations/month for free
after which you pay $.005 per invalidation request. More than one file
can be included in each request. The script will invalidate at least 4
paths on each invalidation request:</p>
<ul>
<li><code>/index.html</code></li>
<li><code>/orepan2/02package.details.text.gz</code></li>
<li><code>/orepan2/orepan2-cache.json</code></li>
<li>the distribution you just uploaded</li>
</ul>
<a id="the-default-index" class="anchor" aria-label="Permalink: The Default Index" href="#the-default-index"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">The Default Index</h2>
<p>A default index page is created for you from a template embedded in
the script. To view the default template:</p>
<pre><code>orepan2-index dump-template
</code></pre>
<p>If you want to create your own template you can provide that using the
C&lt;--template&gt; option or set the <code>template</code> key in your
configuration.</p>
<p>Learn more about templates and customizing your index page by reading
the module documentation (<code>perldoc OrePAN2::S3</code>).</p>
<a id="distribution-documentation" class="anchor" aria-label="Permalink: Distribution Documentation" href="#distribution-documentation"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">Distribution Documentation</h2>
<p>Similar to the way the MetaCPAN sites show your POD as an HTML page,
the default index generated for you will show you a Module Index
listing all of your distributions.</p>
<ul>
<li>If your distribution has a <code>README.md</code> file then an document icon is
placed next to the distribution name. Clicking the icon will bring
up the HTML version of the <code>README.md</code>.</li>
<li>If the primary Perl module in your distribution contains POD another
document icon will be displayed. Clicking that icon will display the
HTML version of the POD from your module.</li>
</ul>
<p><a href="#table-of-contents">Back to Table of Contents</a></p>
<a id="using-a-website-enabled-s3-bucket" class="anchor" aria-label="Permalink: Using a Website Enabled S3 Bucket" href="#using-a-website-enabled-s3-bucket"><span aria-hidden="true" class="octicon octicon-link"></span></a><h1 class="heading-element">Using a Website Enabled S3 Bucket</h1>
<p>As explained
<a href="https://blog.tbcdevelopmentgroup.com/2025-02-18-post.html" rel="nofollow">here</a>,
there are many ways to create static websites. One such way is to use
a feature of S3 that allows you to serve content directly from the
bucket. In order to use HTTPS however, you would need to front the
bucket using CloudFront and optionally install your own certificate
and domain name.</p>
<p>If you don't want or need that kind of security and simply want to
plow ahead with an insecure public bucket, you can do so. In that case
you might want to at least create a bucket policy to restrict the IPs
addresses that can access your bucket. Caveat Emptor.</p>
<p>To use an insecure bucket, simply remove the DistributionId from the
configuration file.</p>
<p>You'll find a script <a href="bin/create-insecure-bucket">here</a> that will
allow you to create your insecure website enabled bucket.</p>
<a id="warning" class="anchor" aria-label="Permalink: WARNING!" href="#warning"><span aria-hidden="true" class="octicon octicon-link"></span></a><h2 class="heading-element">WARNING!</h2>
<p>Take a look at this <a href="https://blog.tbcdevelopmentgroup.com/2025-02-21-post.html" rel="nofollow">blog
post</a>
before you blithely lock down your S3 bucket using an IP address.</p>
<p><a href="#table-of-contents">Back to Table of Contents</a></p>
